import '../../domain/entities/university_entity.dart';

abstract class UniversitiesRepository {
  // إكمال بيانات البروفايل عند التسجيل أو التحديث
  Future<void> completeStudentProfile({
    required double gpa,
    double? academicAverage,
    double? highSchoolScore,
    required double maxGpa,
    required double minGpa,
    required bool hasMoi,
    required bool hasIelts,
    double? ieltsScore,
    required String targetMajor,
    required String intake,
    required String languagePreference,
    required String degreeLevel,
    bool hasGermanCert = false,
    String? germanCertType,
    String? germanCertLevel,
  });

  // 🎯 جلب الجامعات مع دعم الصفحات (Pagination)
  Future<List<UniversityEntity>> fetchMatchedUniversities({
    int page = 1,
    int limit = 10,
  });
}
