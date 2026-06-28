import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/match_score_calculator.dart';

abstract class UniversitiesRemoteDataSource {
  Future<void> updateStudentProfile(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getCurrentStudentProfile(String userId);
  Future<List<Map<String, dynamic>>> fetchMatchedUniversitiesRaw({
    required String userId,
    required int page,
    required int limit,
  });
}

class UniversitiesRemoteDataSourceImpl implements UniversitiesRemoteDataSource {
  final SupabaseClient client;
  UniversitiesRemoteDataSourceImpl(this.client);

  @override
  Future<void> updateStudentProfile(Map<String, dynamic> data) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    // 🎯 استخدام الحقول الصحيحة التي أصلحناها في الـ SQL
    await client.from('profiles').update(data).eq('id', user.id).timeout(const Duration(seconds: 10));
  }

  @override
  Future<Map<String, dynamic>> getCurrentStudentProfile(String userId) async {
    final result = await client.from('profiles').select('degree_level, preferred_cities, budget_range, gpa, max_gpa, academic_average, high_school_score, has_ielts, ielts_score, has_toefl, toefl_score, has_moi, target_major, language_preference, has_transcripts, has_bachelor_cert, has_sop, has_cv, has_german_cert_doc').eq('id', userId).maybeSingle().timeout(const Duration(seconds: 10));
    return result ?? <String, dynamic>{};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMatchedUniversitiesRaw({
    required String userId,
    required int page,
    required int limit,
  }) async {
    try {
      final studentData = await getCurrentStudentProfile(userId);

      String searchDegree = "Master";
      String rawDegree = studentData['degree_level'].toString().toLowerCase();
      if (rawDegree.contains("bachelor")) {
        searchDegree = "Bachelor";
      } else if (rawDegree.contains("doctor") || rawDegree.contains("phd")) {
        searchDegree = "Doctorate";
      }

      // ── استخراج preferred cities و budget range ────────────
      final List<String> preferredCities = _parsePreferredCities(
        studentData['preferred_cities'],
      );

      final num? budgetMax = _parseBudgetMax(
        studentData['budget_range']?.toString(),
      );

      // 🎯 جلب الجامعات — من Hive Cache أو Supabase
      final cached = await LocalStorageService.getOfflineData<String>(
        'universities_all',
        maxAge: const Duration(hours: 1),
      );
      List<Map<String, dynamic>> unis;
      if (cached != null) {
        unis = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
      } else {
        final response = await client
            .from('universities')
            .select('*, university_programs!inner(*)')
            .eq('country', 'Germany')
            .eq('university_programs.degree_type', searchDegree)
            .order('name', ascending: true).timeout(const Duration(seconds: 10));
        unis = List<Map<String, dynamic>>.from(response as List);
        await LocalStorageService.cacheOfflineData(
          'universities_all',
          jsonEncode(unis),
        );
      }

      // 🎯 حساب scores في Isolate منفصل عشان ميبقاش على main thread
      final scoredUnis = await compute(_scoreAndSortUniversities, {
        'unis': unis,
        'studentData': studentData,
        'preferredCities': preferredCities,
        'budgetMax': budgetMax,
      });
      return scoredUnis;
    } catch (e) {
      log.e("DataSource error: $e");
      throw Exception('Failed to fetch data');
    }
  }

  /// يحوّل preferred_cities (List أو String) إلى List<String>
  List<String> _parsePreferredCities(dynamic cities) {
    if (cities == null) return [];
    if (cities is List) {
      return cities.map((e) => e.toString()).toList();
    }
    final String str = cities.toString();
    if (str.isEmpty) return [];
    // احتمال string بصيغة ['Berlin', 'Munich'] أو Berlin,Munich
    final cleaned = str
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll("'", '')
        .replaceAll('"', '');
    return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// يستخرج الحد الأقصى للميزانية من budget_range string
  num? _parseBudgetMax(String? budgetRange) {
    if (budgetRange == null || budgetRange.isEmpty) return null;
    final lower = budgetRange.toLowerCase();
    if (lower.contains('not sure') || lower.contains('above')) return null;
    final match = RegExp(r'(\d[\d,]*)').firstMatch(budgetRange);
    if (match == null) return null;
    return int.parse(match.group(1)!.replaceAll(',', ''));
  }

  /// يحوّل قيمة (num أو String) إلى int بأمان
  static int _parseIntStatic(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) return 0;
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }
}

// ─── Top-level function for compute() isolate ────────────────
List<Map<String, dynamic>> _scoreAndSortUniversities(Map<String, dynamic> params) {
  final unis = (params['unis'] as List).cast<Map<String, dynamic>>();
  final studentData = params['studentData'] as Map<String, dynamic>;
  final preferredCities = (params['preferredCities'] as List?)?.cast<String>() ?? [];
  final budgetMax = params['budgetMax'] as num?;

  final List<Map<String, dynamic>> scoredUnis = [];

  for (final uni in unis) {
    final rawPrograms = uni['university_programs'] as List;
    int maxScore = 0;
    final List<Map<String, dynamic>> validPrograms = [];

    final uniLocation = (uni['location'] as String? ?? '').toLowerCase();
    final isPreferredCity = preferredCities.isEmpty
        ? false
        : preferredCities.any((c) => uniLocation.contains(c.toLowerCase()));
    final int locationBonus = isPreferredCity ? 8 : 0;

    for (final p in rawPrograms) {
      int score = MatchScoreCalculator.calculate(
        studentProfile: studentData,
        programRequiredGpa: (p['required_gpa'] as num?)?.toDouble() ?? 0.0,
        programRequiresIelts: p['requires_ielts'] ?? false,
        programMinIelts: (p['min_ielts_score'] as num?)?.toDouble() ?? 0.0,
        programAcceptsMoi: p['accepts_moi'] ?? false,
        programMajor: p['major']?.toString() ?? '',
        programName: p['program_name']?.toString() ?? '',
        programLanguage: p['instruction_language']?.toString() ?? 'English',
        programDegree: p['degree_type']?.toString() ?? '',
      );

      if (score > 0) {
        final int tuitionFee = UniversitiesRemoteDataSourceImpl._parseIntStatic(
          p['tuition_fee_per_year'],
        );
        int budgetAdjustment = 0;
        if (budgetMax != null && tuitionFee > 0) {
          budgetAdjustment = tuitionFee <= budgetMax ? 5 : -5;
        }

        score = (score + locationBonus + budgetAdjustment).clamp(0, 100);
        p['calculated_score'] = score;
        p['is_recommended'] = score >= 60;
        validPrograms.add(p);
        if (score > maxScore) maxScore = score;
      }
    }

    if (validPrograms.isNotEmpty) {
      uni['university_programs'] = validPrograms;
      uni['calculated_score'] = maxScore;
      scoredUnis.add(uni);
    }
  }

  scoredUnis.sort((a, b) => (b['calculated_score'] as int)
      .compareTo(a['calculated_score'] as int));
  return scoredUnis;
}
