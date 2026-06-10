import '../../domain/entities/program_entity.dart';

class ProgramModel extends ProgramEntity {
  ProgramModel({
    required super.id,
    required super.programName,
    required super.major,
    required super.requiredGpa,
    required super.requiresIelts,
    required super.minIeltsScore,
    required super.acceptsMoi,
    required super.instructionLanguage,
    required super.degreeType,
    super.deadline,
    super.applicationFee,
    super.tuitionFeePerYear,
    super.curriculum,
    super.isRecommended,
    required super.intakeType,
    required super.matchScore,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id']?.toString() ?? '',
      programName:
          json['program_name']?.toString() ??
          json['major']?.toString() ??
          'Unnamed Program',
      major: json['major']?.toString() ?? '',
      requiredGpa:
          (double.tryParse(json['required_gpa']?.toString() ?? '0') ?? 0.0),
      requiresIelts:
          json['requires_ielts'] == true || json['requires_ielts'] == 'true',
      minIeltsScore:
          (double.tryParse(json['min_ielts_score']?.toString() ?? '0') ?? 0.0),
      acceptsMoi: json['accepts_moi'] == true || json['accepts_moi'] == 'true',
      instructionLanguage:
          json['instruction_language']?.toString() ?? 'English',
      degreeType: json['degree_type']?.toString() ?? 'Master',
      deadline: json['deadline']?.toString(),
      applicationFee:
          (int.tryParse(json['application_fee']?.toString() ?? '0') ?? 0),
      tuitionFeePerYear:
          (int.tryParse(json['tuition_fee_per_year']?.toString() ?? '0') ?? 0),
      curriculum: json['curriculum']?.toString() ?? "No details",
      isRecommended:
          json['is_recommended'] == true || json['is_recommended'] == 'true',
      intakeType: json['intake_type']?.toString() ?? 'Winter',
      matchScore:
          int.tryParse(json['calculated_score']?.toString() ?? '0') ?? 0,
    );
  }

  ProgramEntity toEntity() {
    return ProgramEntity(
      id: id,
      programName: programName,
      major: major,
      requiredGpa: requiredGpa,
      requiresIelts: requiresIelts,
      minIeltsScore: minIeltsScore,
      acceptsMoi: acceptsMoi,
      instructionLanguage: instructionLanguage,
      degreeType: degreeType,
      deadline: deadline,
      applicationFee: applicationFee,
      tuitionFeePerYear: tuitionFeePerYear,
      curriculum: curriculum,
      isRecommended: isRecommended,
      intakeType: intakeType,
      matchScore: matchScore,
    );
  }
}
