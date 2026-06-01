import '../../domain/entities/university_entity.dart';

class UniversityModel extends UniversityEntity {
  UniversityModel({
    required super.id,
    required super.name,
    required super.program,
    required super.matchPercentage,
    required super.logoText,
    required super.requiredGpa,
    required super.requiresIelts,
    required super.minIeltsScore,
    required super.country,
    super.status,
    super.notes,
    super.hasTranscripts,
    super.hasCv,
    super.hasSop,
    super.hasBachelorCert,
    super.description,
    super.curriculum,
    super.rankings,
    super.logoUrl,
    super.deadline,
    super.applicationFee,
    super.tuitionFeePerYear,
    super.location,
    super.websiteUrl,
    required super.acceptsMoi, // 👈 تمرير الـ MOI
    required super.instructionLanguage, // 👈 تمرير لغة التدريس الحقيقية
    required super.degreeType, // 👈 تمرير نوع الدرجة
  });
  @override
  // 🎯 دالة الـ copyWith المضافة لنسخ الكائن وتعديل قيم معينة دون تصفير الباقي
  UniversityModel copyWith({
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
    bool? hasCv,
    bool? hasSop,
    bool? hasBachelorCert,
    String? description,
    String? curriculum,
    dynamic
    rankings, // ديناميك ليطابق نوع الـ Entity (سواء كان int أو حسب تعريف السوبر)
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
    return UniversityModel(
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
      hasCv: hasCv ?? this.hasCv,
      hasSop: hasSop ?? this.hasSop,
      hasBachelorCert: hasBachelorCert ?? this.hasBachelorCert,
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

  static int calculateAcademicMatch({
    required double requiredGpa,
    required bool requiresIelts,
    required double minIeltsScore,
    required bool acceptsMoi,
    required String uniProgram,
    required Map<String, dynamic> studentProfile,
  }) {
    double studentGpa = (studentProfile['gpa'] as num?)?.toDouble() ?? 0.0;
    double maxGpa = (studentProfile['max_gpa'] as num?)?.toDouble() ?? 4.0;
    double minGpa = (studentProfile['min_gpa'] as num?)?.toDouble() ?? 2.0;

    bool studentHasIelts = studentProfile['has_ielts'] as bool? ?? false;
    double studentIeltsScore =
        (studentProfile['ielts_score'] as num?)?.toDouble() ?? 0.0;
    bool studentHasMoi = studentProfile['has_moi'] ?? false;
    String studentMajor = (studentProfile['target_major'] as String? ?? '')
        .toLowerCase();

    double studentGermanGpa = 1.0;
    if (maxGpa != minGpa) {
      studentGermanGpa = 1 + 3 * ((maxGpa - studentGpa) / (maxGpa - minGpa));
    }
    studentGermanGpa = studentGermanGpa.clamp(1.0, 6.0);

    bool isMajorMatched =
        studentMajor.isEmpty ||
        uniProgram.isEmpty ||
        uniProgram.toLowerCase().contains(studentMajor) ||
        studentMajor.contains(uniProgram.toLowerCase());

    double totalScore = 0.0;

    if (studentGermanGpa <= requiredGpa) {
      totalScore += 35.0;
      double extraGpa = requiredGpa - studentGermanGpa;
      totalScore += (extraGpa >= 0.5) ? 10.0 : (extraGpa / 0.5) * 10.0;
    } else {
      double shortfall = studentGermanGpa - requiredGpa;
      if (shortfall <= 0.3) totalScore += 15.0;
    }

    bool passesLanguage = false;
    if (!requiresIelts) {
      passesLanguage = true;
    } else {
      if (acceptsMoi && studentHasMoi) {
        passesLanguage = true;
      } else if (studentHasIelts && studentIeltsScore >= minIeltsScore) {
        passesLanguage = true;
      }
    }

    if (passesLanguage) {
      totalScore += 15.0;
      if (studentHasIelts && studentIeltsScore > minIeltsScore) {
        totalScore += 5.0;
      } else if (!requiresIelts || (acceptsMoi && studentHasMoi)) {
        totalScore += 5.0;
      }
    }

    totalScore += isMajorMatched ? 15.0 : 5.0;

    return totalScore.clamp(0.0, 100.0).toInt();
  }

  factory UniversityModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? studentProfile,
    String? status,
    String? notes,
    bool? hasTranscripts,
    bool? hasCv,
    bool? hasSop,
    bool? hasBachelorCert,
  }) {
    final String uniName = json['name'] ?? '';

    Map<String, dynamic>? applicationData;
    if (json['my_applications'] != null) {
      if (json['my_applications'] is List &&
          (json['my_applications'] as List).isNotEmpty) {
        applicationData =
            (json['my_applications'] as List).first as Map<String, dynamic>?;
      } else if (json['my_applications'] is Map) {
        applicationData = json['my_applications'] as Map<String, dynamic>?;
      }
    }

    int parsedRankings = 0;
    if (json['rankings'] != null) {
      if (json['rankings'] is int) {
        parsedRankings = json['rankings'];
      } else {
        parsedRankings = int.tryParse(json['rankings'].toString()) ?? 0;
      }
    }

    double reqGpa = (json['required_gpa'] as num?)?.toDouble() ?? 4.0;
    bool reqIelts = json['requires_ielts'] ?? false;
    double minIelts = (json['min_ielts_score'] as num?)?.toDouble() ?? 0.0;

    bool acceptsMoi = json['accepts_moi'] as bool? ?? false;
    String instructionLang =
        json['instruction_language']?.toString() ?? 'English';
    String degreeType = json['degree_type']?.toString() ?? 'Bachelor';

    String uniProgram =
        json['program_name'] ?? json['major'] ?? json['target_major'] ?? '';

    int finalMatch = 0;
    if (studentProfile != null) {
      finalMatch = calculateAcademicMatch(
        requiredGpa: reqGpa,
        requiresIelts: reqIelts,
        minIeltsScore: minIelts,
        acceptsMoi: acceptsMoi,
        uniProgram: uniProgram,
        studentProfile: studentProfile,
      );
    } else {
      finalMatch = (json['match_percentage'] as num?)?.toInt() ?? 0;
    }

    return UniversityModel(
      id: json['id']?.toString() ?? '',
      name: uniName,
      program: uniProgram,
      logoText: uniName.length >= 3
          ? uniName.substring(0, 3).toUpperCase()
          : 'UNI',
      requiredGpa: reqGpa,
      requiresIelts: reqIelts,
      minIeltsScore: minIelts,
      country: json['country'] ?? '',
      matchPercentage: finalMatch,
      description: json['description'] ?? "No description available",
      curriculum: json['curriculum'] ?? "Curriculum details not provided",
      rankings: parsedRankings,
      logoUrl: json['logo_url'],
      deadline: json['deadline']?.toString(),
      applicationFee: (json['application_fee'] as num?)?.toInt() ?? 0,
      tuitionFeePerYear: (json['tuition_fee_per_year'] as num?)?.toInt() ?? 0,
      location: json['location']?.toString(),
      websiteUrl: json['website_url']?.toString(),
      acceptsMoi: acceptsMoi,
      instructionLanguage: instructionLang,
      degreeType: degreeType,
      status:
          applicationData?['status'] ?? json['status'] ?? status ?? 'unsaved',
      notes: applicationData?['notes'] ?? json['notes'] ?? notes ?? '',
      hasTranscripts:
          applicationData?['has_transcripts'] ??
          json['has_transcripts'] ??
          hasTranscripts ??
          false,
      hasBachelorCert:
          applicationData?['has_bachelor_cert'] ??
          json['has_bachelor_cert'] ??
          hasBachelorCert ??
          false,
      hasSop: applicationData?['has_sop'] ?? json['has_sop'] ?? hasSop ?? false,
      hasCv: applicationData?['has_cv'] ?? json['has_cv'] ?? hasCv ?? false,
    );
  }
}
