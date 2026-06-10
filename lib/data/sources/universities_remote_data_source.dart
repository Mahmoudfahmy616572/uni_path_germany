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
    return await client.from('profiles').select().eq('id', userId).single();
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
      if (rawDegree.contains("bachelor"))
        searchDegree = "Bachelor";
      else if (rawDegree.contains("doctor") || rawDegree.contains("phd"))
        searchDegree = "Doctorate";

      final int from = (page - 1) * limit;
      final int to = from + limit - 1;

      // 🎯 جلب فقط البرامج التي تطابق درجة الطالب الحالية من السيرفر
      final response = await client
          .from('universities')
          .select('*, university_programs(*)')
          .eq('country', 'Germany')
          .ilike('university_programs.degree_type', '%$searchDegree%')
          .range(from, to)
          .order('name', ascending: true);

      final List<Map<String, dynamic>> unis = List<Map<String, dynamic>>.from(
        response as List,
      );
      List<Map<String, dynamic>> finalFilteredUnis = [];

      for (var uni in unis) {
        final rawPrograms = uni['university_programs'] as List;
        int maxScore = 0;
        List<Map<String, dynamic>> validPrograms = [];

        for (var p in rawPrograms) {
          final int score = MatchScoreCalculator.calculate(
            studentProfile: studentData,
            programRequiredGpa: (p['required_gpa'] as num?)?.toDouble() ?? 4.0,
            programRequiresIelts: p['requires_ielts'] ?? false,
            programMinIelts: (p['min_ielts_score'] as num?)?.toDouble() ?? 0.0,
            programAcceptsMoi: p['accepts_moi'] ?? false,
            programMajor: p['major']?.toString() ?? '',
            programName: p['program_name']?.toString() ?? '',
            programIntake: p['intake_type']?.toString() ?? 'Winter',
            programLanguage: p['instruction_language']?.toString() ?? 'English',
            programDegree: p['degree_type']?.toString() ?? '',
          );

          if (score > 0) {
            p['calculated_score'] = score;
            p['is_recommended'] = score >= 60;
            validPrograms.add(p);
            if (score > maxScore) maxScore = score;
          }
        }

        if (validPrograms.isNotEmpty) {
          uni['university_programs'] = validPrograms;
          uni['calculated_score'] = maxScore;
          finalFilteredUnis.add(uni);
        }
      }
      return finalFilteredUnis;
    } catch (e) {
      print("❌ Error in DataSource: $e");
      throw Exception('Failed to fetch data');
    }
  }
}
