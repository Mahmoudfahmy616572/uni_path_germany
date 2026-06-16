import 'package:supabase_flutter/supabase_flutter.dart';

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
    await client.from('profiles').update(data).eq('id', user.id);
  }

  @override
  Future<Map<String, dynamic>> getCurrentStudentProfile(String userId) async {
    final result = await client.from('profiles').select().eq('id', userId).maybeSingle();
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

      // 🎯 جلب كل الجامعات المطابقة لدرجة الطالب الحالية
      final response = await client
          .from('universities')
          .select('*, university_programs(*)')
          .eq('country', 'Germany')
          .ilike('university_programs.degree_type', '%$searchDegree%')
          .order('name', ascending: true);

      final List<Map<String, dynamic>> unis = List<Map<String, dynamic>>.from(
        response as List,
      );
      List<Map<String, dynamic>> scoredUnis = [];

      for (var uni in unis) {
        final rawPrograms = uni['university_programs'] as List;
        int maxScore = 0;
        List<Map<String, dynamic>> validPrograms = [];

        // ── Location bonus (preferred city match) ─────────
        final String uniLocation = (uni['location'] as String? ?? '').toLowerCase();
        final bool isPreferredCity = preferredCities.isEmpty
            ? false
            : preferredCities.any((c) => uniLocation.contains(c.toLowerCase()));
        final int locationBonus = isPreferredCity ? 8 : 0;

        for (var p in rawPrograms) {
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
            // ── Budget bonus/penalty ──────────────────────
            final int tuitionFee = _parseInt(p['tuition_fee_per_year']);
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

      // ترتيب حسب أعلى نقاط مطابقة (الأفضل أولاً)
      scoredUnis.sort((a, b) => (b['calculated_score'] as int)
          .compareTo(a['calculated_score'] as int));
      return scoredUnis;
    } catch (e) {
      print("❌ Error in DataSource: $e");
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
  int _parseInt(dynamic value) {
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
