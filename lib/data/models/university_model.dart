import '../../domain/entities/university_entity.dart';

class UniversityModel extends UniversityEntity {
  UniversityModel({
    required super.logoText,
    required super.name,
    required super.program,
    required super.matchPercentage,
  });

  // هنا بنستقبل الداتا من Supabase مثلاً
  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
      logoText: json['logo_text'] ?? '',
      name: json['name'] ?? '',
      program: json['program'] ?? '',
      matchPercentage: json['match_percentage'] ?? 0,
    );
  }
}
