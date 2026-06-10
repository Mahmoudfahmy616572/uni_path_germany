class ProgramEntity {
  final String id;
  final String programName;
  final String major;
  final double requiredGpa;
  final bool requiresIelts;
  final double minIeltsScore;
  final bool acceptsMoi;
  final String instructionLanguage;
  final String degreeType;
  final String? deadline;
  final int applicationFee;
  final int tuitionFeePerYear;
  final String? curriculum;
  final bool isRecommended;
  final String intakeType;
  final int matchScore;

  ProgramEntity({
    required this.id,
    required this.programName,
    required this.major,
    required this.requiredGpa,
    required this.requiresIelts,
    required this.minIeltsScore,
    required this.acceptsMoi,
    required this.instructionLanguage,
    required this.degreeType,
    this.deadline,
    this.applicationFee = 0,
    this.tuitionFeePerYear = 0,
    this.curriculum,
    this.isRecommended = true,
    this.intakeType = 'Winter',
    this.matchScore = 0,
  });
}
