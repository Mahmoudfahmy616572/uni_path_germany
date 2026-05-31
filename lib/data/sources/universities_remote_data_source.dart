import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UniversitiesRemoteDataSource {
  Future<void> updateStudentProfile({
    required double gpa,
    required double maxGpa,
    required double minGpa,
    required bool hasMoi,
    required bool hasIelts,
    double? ieltsScore,
    required String targetMajor,
    required String targetCountry,
  });
  Future<Map<String, dynamic>> getCurrentStudentProfile(String userId);
  Future<List<Map<String, dynamic>>> fetchUniversitiesWithApplicationStatus(
    String userId,
  );
}

class UniversitiesRemoteDataSourceImpl implements UniversitiesRemoteDataSource {
  final SupabaseClient client;
  UniversitiesRemoteDataSourceImpl(this.client);

  @override
  Future<void> updateStudentProfile({
    required double gpa,
    required double maxGpa,
    required double minGpa,
    required bool hasMoi,
    required bool hasIelts,
    double? ieltsScore,
    required String targetMajor,
    required String targetCountry,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client
        .from('profiles')
        .update({
          'gpa': gpa,
          'max_gpa': maxGpa,
          'min_gpa': minGpa,
          'has_moi': hasMoi,
          'has_ielts': hasIelts,
          'ielts_score': hasIelts ? ieltsScore : null,
          'target_major': targetMajor,
          'target_country': targetCountry,
        })
        .eq('id', user.id);
  }

  @override
  Future<Map<String, dynamic>> getCurrentStudentProfile(String userId) async {
    // 🔥 تم تحديث الـ select لتجلب الحقول الجديدة من سوبابيز بنجاح ومنع الكراش
    return await client
        .from('profiles')
        .select(
          'gpa, max_gpa, min_gpa, has_moi, has_ielts, ielts_score, target_major, target_country',
        )
        .eq('id', userId)
        .single();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUniversitiesWithApplicationStatus(
    String userId,
  ) async {
    try {
      // 🔥 التصحيح المليمتري هنا: استخدام الفلترة المضمنة جوه الـ select لجدول الـ Join
      // ده بيخلي الـ left join يرجع الجامعة حتى لو اليوزر مش عامل لها save، فـ تتحدث الحالة فوراً محلياً!
      final List<dynamic> data = await client
          .from('test_universities')
          .select('*, my_applications!left(*).where(user_id.eq.$userId)');

      return data.map<Map<String, dynamic>>((element) {
        return Map<String, dynamic>.from(element as Map);
      }).toList();
    } catch (e) {
      print("❌ Error in fetchUniversitiesWithApplicationStatus: $e");
      throw Exception('فشل جلب بيانات الجامعات: ${e.toString()}');
    }
  }
}
