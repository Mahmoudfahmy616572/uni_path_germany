import 'package:supabase_flutter/supabase_flutter.dart';

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
    required String targetCountry,
  }) async {
    try {
      await remoteDataSource.updateStudentProfile(
        gpa: gpa,
        maxGpa: maxGpa,
        minGpa: minGpa,
        hasMoi: hasMoi,
        hasIelts: hasIelts,
        ieltsScore: ieltsScore,
        targetMajor: targetMajor,
        targetCountry: targetCountry,
      );
    } catch (e) {
      throw Exception('فشل تحديث البيانات: ${e.toString()}');
    }
  }

  @override
  Future<List<UniversityModel>> fetchMatchedUniversities() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. جلب بروفايل الطالب كاملاً بالحقول الجديدة
      final studentData = await remoteDataSource.getCurrentStudentProfile(
        user.id,
      );

      String studentCountry = (studentData['target_country'] as String? ?? '')
          .trim()
          .toLowerCase();

      // 2. جلب داتا الجامعات المشبوكة بـ Left Join المرن
      final rawUnis = await remoteDataSource
          .fetchUniversitiesWithApplicationStatus(user.id);

      List<UniversityModel> matchedList = [];

      for (var json in rawUnis) {
        String uniCountry = (json['country'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        // فلترة الدولة لو الطالب محدد بلد مستهدف
        if (studentCountry.isNotEmpty && uniCountry != studentCountry) continue;

        final myAppsList = json['my_applications'] as List?;
        String currentStatus = 'unsaved';

        if (myAppsList != null && myAppsList.isNotEmpty) {
          currentStatus = myAppsList.first['status'] ?? 'saved';
        }

        // بناء الموديل وتمرير البروفايل للحسبة الموحدة
        matchedList.add(
          UniversityModel.fromJson(
            json,
            studentProfile: studentData, // 👈 التمرير السحري لتوحيد النسب
            status: currentStatus,
          ),
        );
      }

      matchedList.sort(
        (a, b) => b.matchPercentage.compareTo(a.matchPercentage),
      );
      return matchedList;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
  