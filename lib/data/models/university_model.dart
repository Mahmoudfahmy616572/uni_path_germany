import '../../domain/entities/program_entity.dart';
import '../../domain/entities/university_entity.dart';
import 'program_model.dart';

class UniversityModel extends UniversityEntity {
  UniversityModel({
    required super.id,
    required super.name,
    required super.matchPercentage,
    required super.logoText,
    required super.country,
    required super.programs,
    super.matchedProgramsCount,
    super.status,
    super.notes,
    super.hasTranscripts,
    super.hasCv,
    super.hasSop,
    super.hasBachelorCert,
    super.hasLanguageCert,
    super.description,
    super.rankings,
    super.logoUrl,
    super.imageUrl,
    super.location,
    super.websiteUrl,
    super.portalUrl,
    super.portalStatus,
    super.paymentStatus,
    super.submittedAt,
    super.autoTrack,
  });

  factory UniversityModel.fromJson(
    Map<String, dynamic> json, {
    int calculatedScore = 0,
    String? currentStatus,
  }) {
    final String uniName = json['name'] ?? 'Unknown University';

    var programsList = <ProgramEntity>[];
    if (json['university_programs'] != null) {
      programsList = (json['university_programs'] as List)
          .map(
            (p) => ProgramModel.fromJson(
              Map<String, dynamic>.from(p as Map),
            ).toEntity(),
          )
          .toList();
    }

    return UniversityModel(
      id: json['id']?.toString() ?? '',
      name: uniName,
      country: json['country'] ?? 'Germany',
      programs: programsList,
      matchPercentage: calculatedScore > 0
          ? calculatedScore
          : (json['calculated_score'] ?? 15),
      description: json['description'] ?? "No description",
      status: currentStatus ?? json['status'] ?? 'unsaved',
      logoText: uniName.isNotEmpty ? uniName[0].toUpperCase() : 'U',
      matchedProgramsCount: programsList.where((p) => p.isRecommended).length,
      rankings: int.tryParse(json['rankings']?.toString() ?? '0') ?? 0,
      logoUrl: json['logo_url'],
      imageUrl: json['image_url'],
      location: json['location']?.toString() ?? json['country'] ?? 'Unknown',
      websiteUrl: json['website_url']?.toString(),
      notes: json['notes']?.toString() ?? '',
      hasTranscripts: json['has_transcripts'],
      hasCv: json['has_cv'],
      hasSop: json['has_sop'],
      hasBachelorCert: json['has_bachelor_cert'],
      hasLanguageCert: json['has_language_cert'],
      portalUrl: json['portal_url']?.toString(),
      portalStatus: json['portal_status']?.toString() ?? 'pending',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      submittedAt: json['submitted_at']?.toString(),
      autoTrack: json['auto_track'] == true,
    );
  }

  UniversityEntity toEntity() {
    return UniversityEntity(
      id: id,
      name: name,
      matchPercentage: matchPercentage,
      logoText: logoText,
      country: country,
      programs: programs,
      matchedProgramsCount: matchedProgramsCount,
      status: status,
      notes: notes,
      hasTranscripts: hasTranscripts,
      hasCv: hasCv,
      hasSop: hasSop,
      hasBachelorCert: hasBachelorCert,
      hasLanguageCert: hasLanguageCert,
      description: description,
      rankings: rankings,
      logoUrl: logoUrl,
      imageUrl: imageUrl,
      location: location,
      websiteUrl: websiteUrl,
      portalUrl: portalUrl,
      portalStatus: portalStatus,
      paymentStatus: paymentStatus,
      submittedAt: submittedAt,
      autoTrack: autoTrack,
    );
  }
}
