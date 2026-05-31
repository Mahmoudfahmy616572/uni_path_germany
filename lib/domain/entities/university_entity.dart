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

  // 🔥 الحقول اللي كانت مسببة الأيرور نقلناها هنا عشان الـ Cubit يشوفها علطول
  final String? description;
  final String? curriculum;
  final int? rankings;
  final String? logoUrl;
  final String? deadline;
  final int applicationFee;
  final int tuitionFeePerYear;

  // 👇 الحقول الجديدة
  final String? location;
  final String? websiteUrl;

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
    this.location, // 👈 ضفناها هنا
    this.websiteUrl, // 👈 وضفناها هنا
  });
}
