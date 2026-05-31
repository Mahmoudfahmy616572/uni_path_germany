import '../../data/models/university_model.dart';

abstract class UniversitiesRepository {
  Future<void> completeStudentProfile({
    required double gpa,
    required double maxGpa,
    required double minGpa,
    required bool hasMoi,
    required bool hasIelts,
    double? ieltsScore,
    required String targetMajor,
    required String targetCountry,
  });

  Future<List<UniversityModel>> fetchMatchedUniversities();
}
