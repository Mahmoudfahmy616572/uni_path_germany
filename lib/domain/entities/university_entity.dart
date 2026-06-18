import 'program_entity.dart';

class UniversityEntity {
  final String id;
  final String name;
  final int matchPercentage;
  final String logoText;
  final String country;
  final int matchedProgramsCount;

  final List<ProgramEntity> programs;
  final String status;
  final String notes;

  // 🎯 الحقول التي تم إصلاحها لتقبل الروابط (نص) أو القيمة القديمة (bool)
  final dynamic hasTranscripts;
  final dynamic hasBachelorCert;
  final dynamic hasSop;
  final dynamic hasCv;
  final dynamic hasLanguageCert;

  final String? description;
  final int? rankings;
  final String? logoUrl;
  final String? imageUrl;
  final String? location;
  final String? websiteUrl;

  // Portal tracking fields
  final String? portalUrl;
  final String portalStatus;
  final String paymentStatus;
  final String? submittedAt;
  final bool autoTrack;

  UniversityEntity({
    required this.id,
    required this.name,
    required this.matchPercentage,
    required this.logoText,
    required this.country,
    required this.programs,
    this.matchedProgramsCount = 1,
    this.status = 'unsaved',
    this.notes = '',
    this.hasTranscripts = false,
    this.hasBachelorCert = false,
    this.hasSop = false,
    this.hasCv = false,
    this.hasLanguageCert = false,
    this.description,
    this.rankings,
    this.logoUrl,
    this.imageUrl,
    this.location,
    this.websiteUrl,
    this.portalUrl,
    this.portalStatus = 'pending',
    this.paymentStatus = 'unpaid',
    this.submittedAt,
    this.autoTrack = false,
  });

  UniversityEntity copyWith({
    String? id,
    String? name,
    int? matchPercentage,
    String? logoText,
    String? country,
    List<ProgramEntity>? programs,
    int? matchedProgramsCount,
    String? status,
    String? notes,
    dynamic hasTranscripts,
    dynamic hasBachelorCert,
    dynamic hasSop,
    dynamic hasCv,
    dynamic hasLanguageCert,
    String? description,
    int? rankings,
    String? logoUrl,
    String? imageUrl,
    String? location,
    String? websiteUrl,
    String? portalUrl,
    String? portalStatus,
    String? paymentStatus,
    String? submittedAt,
    bool? autoTrack,
  }) {
    return UniversityEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      logoText: logoText ?? this.logoText,
      country: country ?? this.country,
      programs: programs ?? this.programs,
      matchedProgramsCount: matchedProgramsCount ?? this.matchedProgramsCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      hasTranscripts: hasTranscripts ?? this.hasTranscripts,
      hasBachelorCert: hasBachelorCert ?? this.hasBachelorCert,
      hasSop: hasSop ?? this.hasSop,
      hasCv: hasCv ?? this.hasCv,
      hasLanguageCert: hasLanguageCert ?? this.hasLanguageCert,
      description: description ?? this.description,
      rankings: rankings ?? this.rankings,
      logoUrl: logoUrl ?? this.logoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      portalUrl: portalUrl ?? this.portalUrl,
      portalStatus: portalStatus ?? this.portalStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      autoTrack: autoTrack ?? this.autoTrack,
    );
  }
}
