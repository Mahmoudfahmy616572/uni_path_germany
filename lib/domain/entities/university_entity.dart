class UniversityEntity {
  final String id;
  final String name;
  final String program;
  final int matchPercentage;
  final String logoText;
  final double requiredGpa;
  final bool requiresIelts;
  final double minIeltsScore;
  final String country;

  // الحقول الخاصة بالـ Checklist والحالة
  final String status;
  final String notes;
  final bool hasTranscripts;
  final bool hasBachelorCert;
  final bool hasSop;
  final bool hasCv;

  final String? description;
  final String? curriculum;
  final int? rankings;
  final String? logoUrl;
  final String? deadline;
  final int applicationFee;
  final int tuitionFeePerYear;

  final String? location;
  final String? websiteUrl;

  // الحقول الجديدة الخاصة باللغة والـ MOI المرفوعة للداتابيز
  final bool acceptsMoi;
  final String instructionLanguage;
  final String degreeType;

  UniversityEntity({
    required this.id,
    required this.name,
    required this.program,
    required this.matchPercentage,
    required this.logoText,
    required this.requiredGpa,
    required this.requiresIelts,
    required this.minIeltsScore,
    required this.country,
    this.status = 'unsaved',
    this.notes = '',
    this.hasTranscripts = false,
    this.hasBachelorCert = false,
    this.hasSop = false,
    this.hasCv = false,
    this.description,
    this.curriculum,
    this.rankings,
    this.logoUrl,
    this.deadline,
    this.applicationFee = 0,
    this.tuitionFeePerYear = 0,
    this.location,
    this.websiteUrl,
    this.acceptsMoi = false,
    this.instructionLanguage = 'English',
    this.degreeType = 'Bachelor',
  });

  // 🎯 دالة الـ copyWith المضافة لتعديل البيانات (مثل النسبة) بأمان على مستوى الـ Entity
  UniversityEntity copyWith({
    String? id,
    String? name,
    String? program,
    int? matchPercentage,
    String? logoText,
    double? requiredGpa,
    bool? requiresIelts,
    double? minIeltsScore,
    String? country,
    String? status,
    String? notes,
    bool? hasTranscripts,
    bool? hasBachelorCert,
    bool? hasSop,
    bool? hasCv,
    String? description,
    String? curriculum,
    int? rankings,
    String? logoUrl,
    String? deadline,
    int? applicationFee,
    int? tuitionFeePerYear,
    String? location,
    String? websiteUrl,
    bool? acceptsMoi,
    String? instructionLanguage,
    String? degreeType,
  }) {
    return UniversityEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      program: program ?? this.program,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      logoText: logoText ?? this.logoText,
      requiredGpa: requiredGpa ?? this.requiredGpa,
      requiresIelts: requiresIelts ?? this.requiresIelts,
      minIeltsScore: minIeltsScore ?? this.minIeltsScore,
      country: country ?? this.country,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      hasTranscripts: hasTranscripts ?? this.hasTranscripts,
      hasBachelorCert: hasBachelorCert ?? this.hasBachelorCert,
      hasSop: hasSop ?? this.hasSop,
      hasCv: hasCv ?? this.hasCv,
      description: description ?? this.description,
      curriculum: curriculum ?? this.curriculum,
      rankings: rankings ?? this.rankings,
      logoUrl: logoUrl ?? this.logoUrl,
      deadline: deadline ?? this.deadline,
      applicationFee: applicationFee ?? this.applicationFee,
      tuitionFeePerYear: tuitionFeePerYear ?? this.tuitionFeePerYear,
      location: location ?? this.location,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      acceptsMoi: acceptsMoi ?? this.acceptsMoi,
      instructionLanguage: instructionLanguage ?? this.instructionLanguage,
      degreeType: degreeType ?? this.degreeType,
    );
  }
}
