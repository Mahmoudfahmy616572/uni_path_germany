import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/university_entity.dart';
import '../../domain/repositories/universities_repository.dart';
import '../models/university_model.dart';
import '../sources/universities_remote_data_source.dart';

class UniversitiesRepositoryImpl implements UniversitiesRepository {
  final UniversitiesRemoteDataSource remoteDataSource;
  final SupabaseClient supabaseClient;

  UniversitiesRepositoryImpl(this.remoteDataSource, this.supabaseClient);

  @override
  Future<void> completeStudentProfile({
    required double gpa,
    required double maxGpa,
    required double minGpa,
    required bool hasMoi,
    required bool hasIelts,
    double? ieltsScore,
    required String targetMajor,
    required String intake,
    required String languagePreference,
    required String degreeLevel, // 🎯 Added degree level
  }) async {
    try {
      // تمرير البيانات للمصدر لتحديثها في قاعدة البيانات
      await remoteDataSource.updateStudentProfile({
        'gpa': gpa,
        'max_gpa': maxGpa,
        'min_gpa': minGpa,
        'has_moi': hasMoi,
        'has_ielts': hasIelts,
        'ielts_score': ieltsScore,
        'target_major': targetMajor,
        'intake': intake,
        'language_preference': languagePreference,
        'degree_level': degreeLevel, // 🎯 Added degree level
        'target_country': 'Germany', // ثابت دائماً
      });
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<List<UniversityEntity>> fetchMatchedUniversities({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // نداء المصدر لجلب البيانات الخام مع مراعاة رقم الصفحة
      final rawMatchedData = await remoteDataSource.fetchMatchedUniversitiesRaw(
        userId: user.id,
        page: page,
        limit: limit,
      );

      // تحويل لستة الـ Maps إلى لستة Entities
      return rawMatchedData.map((uniJson) {
        return UniversityModel.fromJson(
          uniJson,
          calculatedScore: uniJson['calculated_score'] ?? 0,
        ).toEntity();
      }).toList();
    } catch (e) {
      throw Exception('Failed to process matched universities: $e');
    }
  }
}
