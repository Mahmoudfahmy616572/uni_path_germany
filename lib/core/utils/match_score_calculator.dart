// ====================
// FILE: lib/core/utils/match_score_calculator.dart
// ====================
//
// الـ Matching Score بيتحسب من 100 نقطة موزعة كالآتي:
//
//  [35 pts] GPA — Bavarian formula (German GPA)
//  [25 pts] Target Major
//  [15 pts] IELTS / Language Certificate
//  [15 pts] Language of Instruction
//  [10 pts] Application Completeness — document readiness
//
// الإجمالي = 100 نقطة.
// لو الـ degree_level مش متطابق → 0 (hard filter).
//
// GPA: بندخل الدرجة الخام (GPA 4 / GPA 5 / percentage 100%)
// ونحولها لـ German GPA باستخدام معادلة بافاريا الرسمية:
//
//   German GPA = 1 + 3 × (max - achieved) / (max - minPass)
//
// German GPA: 1.0 (أفضل) → 4.0 (أضعف نجاح)
// score = (4.0 - germanGpa) / 3.0 × 35

class MatchScoreCalculator {
  // ─────────────────────────────────────────────────────────
  // Entry point
  // ─────────────────────────────────────────────────────────
  static int calculate({
    required Map<String, dynamic> studentProfile,
    required double programRequiredGpa,
    required bool programRequiresIelts,
    required double programMinIelts,
    required bool programAcceptsMoi,
    required String programMajor,
    required String programName,
    required String programLanguage,
    required String programDegree,
  }) {
    // ── 0. Degree Hard Filter ──────────────────────────────
    final String studentDegreeRaw =
        (studentProfile['degree_level'] as String? ?? '').toLowerCase();

    final String normalizedStudentDegree = _normalizeDegree(studentDegreeRaw);
    final String normalizedProgramDegree = _normalizeDegree(
      programDegree.toLowerCase(),
    );

    if (normalizedStudentDegree.isNotEmpty &&
        normalizedProgramDegree.isNotEmpty &&
        normalizedStudentDegree != normalizedProgramDegree) {
      return 0;
    }

    // ── استخراج بيانات الطالب ─────────────────────────────
    final double germanGpa = _resolveStudentGermanGpa(studentProfile);

    final bool studentHasIelts = studentProfile['has_ielts'] as bool? ?? false;
    final double studentIeltsScore =
        (studentProfile['ielts_score'] as num?)?.toDouble() ?? 0.0;
    final bool studentHasToefl = studentProfile['has_toefl'] as bool? ?? false;
    final double studentToeflScore =
        (studentProfile['toefl_score'] as num?)?.toDouble() ?? 0.0;
    final bool studentHasMoi = studentProfile['has_moi'] as bool? ?? false;

    final String studentTargetMajor =
        (studentProfile['target_major'] as String? ?? '').toLowerCase().trim();
    final String studentLangPref =
        (studentProfile['language_preference'] as String? ?? 'English')
            .toLowerCase()
            .trim();

    int score = 0;

    // ── 1. GPA (35 نقطة) ──────────────────────────────────
    score += _calculateGpaScore(
      germanGpa: germanGpa,
      programRequiredGpa: programRequiredGpa,
    );

    // ── 2. Major (25 نقطة) ────────────────────────────────
    score += _calculateMajorScore(
      studentTargetMajor: studentTargetMajor,
      programMajor: programMajor.toLowerCase(),
      programName: programName.toLowerCase(),
    );

    // ── 3. IELTS / Language Certificate (15 نقطة) ─────────
    score += _calculateIeltsScore(
      programRequiresIelts: programRequiresIelts,
      programMinIelts: programMinIelts,
      programAcceptsMoi: programAcceptsMoi,
      studentHasIelts: studentHasIelts,
      studentIeltsScore: studentIeltsScore,
      studentHasToefl: studentHasToefl,
      studentToeflScore: studentToeflScore,
      studentHasMoi: studentHasMoi,
    );

    // ── 4. Language of Instruction (15 نقطة) ──────────────
    score += _calculateLanguageScore(
      studentLangPref: studentLangPref,
      programLanguage: programLanguage.toLowerCase(),
    );

    // ── 5. Application Completeness (10 نقطة) ─────────────
    score += _calculateCompletenessScore(
      studentProfile: studentProfile,
    );

    return score.clamp(0, 100);
  }

  // ─────────────────────────────────────────────────────────
  // 1. GPA Score — 35 نقطة (Bavarian / German GPA)
  // ─────────────────────────────────────────────────────────
  // ناخد German GPA (1.0 أحسن → 4.0 أضعف نجاح) ونحسب الـ score:
  //
  //   score = (4.0 - germanGpa) / 3.0 × 35
  //
  // 1.0 → 35,  1.5 → 29,  2.0 → 23,  2.5 → 18,
  // 3.0 → 12,  3.5 → 6,   4.0 → 0
  //
  // لو البرنامج عنده requiredGpa (على German scale برضه):
  //   - student ≤ required (أحسن) → المعادلة المستمرة
  //   - student > required (أسوأ) → diff tiers أشد:
  //       +0.1 → 30,  +0.2 → 25,  +0.3 → 20,
  //       +0.4 → 15,  +0.5 → 10,  +0.75 → 5,  أكثر → 0
  // ─────────────────────────────────────────────────────────
  static int _calculateGpaScore({
    required double germanGpa,
    required double programRequiredGpa,
  }) {
    if (germanGpa <= 0 || germanGpa > 4.0) return 0;

    if (programRequiredGpa > 0) {
      // German scale: lower = better. student ≤ required → meets.
      final double diff = programRequiredGpa - germanGpa;
      if (diff >= 0) {
        final double pctBetter = (4.0 - germanGpa) / 3.0;
        return (pctBetter * 35).round().clamp(0, 35);
      }
      final double belowBy = -diff; // positive
      if (belowBy <= 0.1) return 30;
      if (belowBy <= 0.2) return 25;
      if (belowBy <= 0.3) return 20;
      if (belowBy <= 0.4) return 15;
      if (belowBy <= 0.5) return 10;
      if (belowBy <= 0.75) return 5;
      return 0;
    }

    final double pctBetter = (4.0 - germanGpa) / 3.0;
    return (pctBetter * 35).round().clamp(0, 35);
  }

  // ─────────────────────────────────────────────────────────
  // 2. Major Score — 25 نقطة
  // ─────────────────────────────────────────────────────────
  // علميًا (وفقًا لـ DAAD / uni-assist):
  //   - فحص "related subject" (fachverwandt) → binary: related أو لا
  //   - ما فيهش scoring متدرج — دا اختراعنا لتوصية الطالب
  //
  //  exact match (نفس التخصص)       → 25 (related subject)
  //  same category (نفس المجال)      → 10 (قد يكون related)
  //  weak match (broad via name)     → 5  (hint فقط)
  //  no match / غير محدد             → 0
  // ─────────────────────────────────────────────────────────
  static int _calculateMajorScore({
    required String studentTargetMajor,
    required String programMajor,
    required String programName,
  }) {
    if (studentTargetMajor.isEmpty) return 0;

    // Exact match
    if (programMajor == studentTargetMajor ||
        programMajor.contains(studentTargetMajor) ||
        studentTargetMajor.contains(programMajor)) {
      return 25;
    }

    // Keyword-based category matching
    final studentCategory = _getMajorCategory(studentTargetMajor);
    final programCategory = _getMajorCategory(programMajor);

    if (studentCategory != null &&
        programCategory != null &&
        studentCategory == programCategory) {
      return 10;
    }

    // Check program name as fallback
    if (programName.contains(studentTargetMajor) ||
        studentTargetMajor
            .split(' ')
            .any((word) => word.length > 3 && programMajor.contains(word))) {
      return 5;
    }

    return 0;
  }

  // بنصنف كل major في category أشمل
  static String? _getMajorCategory(String major) {
    final Map<String, List<String>> categories = {
      'computer_it': [
        'computer science',
        'computer science & it',
        'information systems',
        'artificial intelligence',
        'cybersecurity',
        'bioinformatics',
        'software',
        'data science',
        'information technology',
      ],
      'engineering': [
        'engineering',
        'mechanical engineering',
        'civil engineering',
        'aerospace engineering',
        'automotive engineering',
        'chemical engineering',
        'energy engineering',
        'robotics',
        'microelectronics',
        'photonics',
        'nanostructure technology',
        'polymer science',
      ],
      'business': [
        'business',
        'business & management',
        'business administration',
        'economics',
        'finance',
        'management',
        'marketing',
      ],
      'medicine_health': [
        'medicine',
        'healthcare',
        'healthcare medicine',
        'pharmaceutical sciences',
        'human biology',
        'biochemistry',
      ],
      'science': [
        'natural sciences',
        'mathematics',
        'environmental science',
        'marine biology',
        'oceanography',
        'physics',
        'chemistry',
      ],
      'social': ['social sciences', 'political science', 'economics', 'law'],
    };

    for (final entry in categories.entries) {
      for (final keyword in entry.value) {
        if (major.contains(keyword) || keyword.contains(major)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // 3. IELTS / Language Certificate Score — 15 نقطة
  // ─────────────────────────────────────────────────────────
  // Scenarios:
  //
  //  البرنامج بيطلب IELTS:
  //    - الطالب عنده IELTS وفوق الـ minimum  → 15 نقطة
  //    - الطالب عنده IELTS بس تحت الـ minimum → 5 نقطة
  //    - البرنامج بيقبل MOI والطالب عنده MOI  → 10 نقطة (بديل)
  //    - الطالب معهوش شهادة خالص             → 0 نقطة
  //
  //  البرنامج مش بيطلب IELTS:
  //    - الطالب عنده IELTS                   → 15 نقطة (ميزة)
  //    - الطالب معهوش                        → 15 نقطة (مش مطلوب أصلاً)
  // ─────────────────────────────────────────────────────────
  static int _calculateIeltsScore({
    required bool programRequiresIelts,
    required double programMinIelts,
    required bool programAcceptsMoi,
    required bool studentHasIelts,
    required double studentIeltsScore,
    required bool studentHasToefl,
    required double studentToeflScore,
    required bool studentHasMoi,
  }) {
    final bool studentMeetsIelts =
        studentHasIelts && studentIeltsScore >= programMinIelts;
    final bool studentCloseToIelts =
        studentHasIelts && studentIeltsScore >= programMinIelts - 0.5;

    // Rough TOEFL→IELTS equivalence: TOEFL 80 ≈ IELTS 6.0, TOEFL 60 ≈ IELTS 5.5
    final double toeflEquivalent = studentHasToefl ? studentToeflScore / 10.0 - 2.0 : 0.0;
    final bool studentMeetsToefl =
        studentHasToefl && toeflEquivalent >= programMinIelts;
    final bool studentCloseToToefl =
        studentHasToefl && toeflEquivalent >= programMinIelts - 0.5;

    if (programRequiresIelts) {
      if (studentMeetsIelts || studentMeetsToefl) return 15;
      if (studentCloseToIelts || studentCloseToToefl) return 8;
      if (studentHasIelts) return 3;
      if (programAcceptsMoi && studentHasMoi) return 10;
      return 0;
    }

    // البرنامج مش بيطلب شهادة لغة
    if (studentHasIelts || studentHasToefl) {
      return 10; // الطالب عنده شهادة بس مش مطلوبة → أولوية أقل
    }
    return 15; // ولا شهادة ولا requirement — مناسب للطالب
  }

  // ─────────────────────────────────────────────────────────
  // 4. Language of Instruction Score — 15 نقطة
  // ─────────────────────────────────────────────────────────
  // Program language: 'english' أو 'german'
  // Student preference: 'english' أو 'german' أو 'both'
  //
  //  perfect match أو student اختار 'both' → 15 نقطة
  //  مش متطابق                             → 3 نقطة (ممكن يتعلم)
  // ─────────────────────────────────────────────────────────
  static int _calculateLanguageScore({
    required String studentLangPref,
    required String programLanguage,
  }) {
    if (studentLangPref == 'both') return 15;
    if (programLanguage == studentLangPref) return 15;
    return 3;
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  // يحوّل "bachelor's degree" → "bachelor"، "master's degree" → "master"، إلخ
  static String _normalizeDegree(String degree) {
    if (degree.contains('bachelor')) return 'bachelor';
    if (degree.contains('master')) return 'master';
    if (degree.contains('doctor') || degree.contains('phd')) return 'doctorate';
    return '';
  }

  // ─────────────────────────────────────────────────────────
  // Bavarian Formula Conversion
  // ─────────────────────────────────────────────────────────
  // تحوّل أي درجة (GPA 4 / GPA 5 / Percentage) لـ German GPA
  // باستخدام معادلة بافاريا الرسمية (المستخدمة في uni-assist و DAAD):
  //
  //   German GPA = 1 + 3 × (max - achieved) / (max - minPass)
  //
  // النتيجة: 1.0 (أفضل) → 4.0 (أضعف نجاح)
  // ─────────────────────────────────────────────────────────
  static double _convertToBavarianGpa(double value, double max, double minPass) {
    if (value <= 0) return 4.0;
    final result = 1 + 3 * (max - value) / (max - minPass);
    return result.clamp(1.0, 4.0);
  }

  // يقرر أي قيمة نستخدمها من الـ profile (GPA 4, GPA 5, Percentage)
  // ويحولها لـ German GPA
  static double _resolveStudentGermanGpa(Map<String, dynamic> profile) {
    final double gpa = (profile['gpa'] as num?)?.toDouble() ?? 0.0;
    final double maxGpa = (profile['max_gpa'] as num?)?.toDouble() ?? 4.0;
    final double academicAverage = (profile['academic_average'] as num?)?.toDouble() ?? 0.0;
    final double highSchoolScore = (profile['high_school_score'] as num?)?.toDouble() ?? 0.0;
    final String? degreeRaw = profile['degree_level'] as String?;
    final bool isBachelor = degreeRaw != null && degreeRaw.toLowerCase().contains('bachelor');

    // تحديد القيمة والـ scale
    double value;
    double max;
    double minPass;

    if (isBachelor) {
      if (academicAverage > 0) {
        value = academicAverage;
        max = academicAverage > 10 ? 100 : 4.0;
        minPass = academicAverage > 10 ? 50 : 1.0;
      } else if (highSchoolScore > 0) {
        value = highSchoolScore;
        max = 100;
        minPass = 50;
      } else if (gpa > 0) {
        value = gpa;
        max = maxGpa;
        minPass = 1.0;
      } else {
        return 4.0;
      }
    } else {
      if (gpa > 0) {
        value = gpa;
        max = maxGpa;
        minPass = 1.0;
      } else if (academicAverage > 0) {
        value = academicAverage;
        max = academicAverage > 10 ? 100 : 4.0;
        minPass = academicAverage > 10 ? 50 : 1.0;
      } else if (highSchoolScore > 0) {
        value = highSchoolScore;
        max = 100;
        minPass = 50;
      } else {
        return 4.0;
      }
    }

    return _convertToBavarianGpa(value, max, minPass);
  }

  // ─────────────────────────────────────────────────────────
  // 5. Application Completeness Score — 10 نقطة
  // ─────────────────────────────────────────────────────────
  // بتقيس مدى جاهزية المستندات الأساسية المطلوبة للتقديم:
  //
  //  Transcripts (كشف الدرجات) موجود     → 3 نقاط
  //  Bachelor Certificate (شهادة البكالوريوس) → 3 نقاط
  //  SOP / Motivation Letter موجود       → 2 نقطة
  //  CV / Resume موجود                   → 2 نقطة
  //                                     ─────
  //                           المجموع   10 نقاط
  //
  // لو المستند مش موجود في الـ profile، بنعتبره 0.
  // ─────────────────────────────────────────────────────────
  static int _calculateCompletenessScore({
    required Map<String, dynamic> studentProfile,
  }) {
    bool hasDoc(String key) {
      final val = studentProfile[key];
      return val is String && val.isNotEmpty;
    }

    int docs = 0;
    if (hasDoc('has_transcripts')) docs += 3;
    if (hasDoc('has_bachelor_cert')) docs += 3;
    if (hasDoc('has_sop')) docs += 2;
    if (hasDoc('has_cv')) docs += 2;
    return docs.clamp(0, 10);
  }

  // ─────────────────────────────────────────────────────────
  // Score Label — للـ UI
  // ─────────────────────────────────────────────────────────
  // بترجع نص وصفي بناءً على الـ score النهائي.
  // ─────────────────────────────────────────────────────────
  static String getScoreLabel(int score) {
    if (score >= 90) return 'Excellent Match';
    if (score >= 75) return 'Strong Match';
    if (score >= 60) return 'Good Match';
    if (score >= 45) return 'Fair Match';
    if (score >= 30) return 'Weak Match';
    return 'Not Recommended';
  }

  // ─────────────────────────────────────────────────────────
  // Score Breakdown — للـ AI explanation (اختياري)
  // ─────────────────────────────────────────────────────────
  // بترجع map بتفاصيل كل component عشان تعرضها للطالب
  // أو تبعتها للـ AI عشان يشرحها.
  // ─────────────────────────────────────────────────────────
  static Map<String, dynamic> getBreakdown({
    required Map<String, dynamic> studentProfile,
    required double programRequiredGpa,
    required bool programRequiresIelts,
    required double programMinIelts,
    required bool programAcceptsMoi,
    required String programMajor,
    required String programName,
    required String programLanguage,
    required String programDegree,
    // programIntake is informational only — not part of the score
    String programIntake = '',
  }) {
    // ── Degree Hard Filter (متطابق مع calculate) ───────────
    final String studentDegreeRaw =
        (studentProfile['degree_level'] as String? ?? '').toLowerCase();
    final String normalizedStudentDegree = _normalizeDegree(studentDegreeRaw);
    final String normalizedProgramDegree = _normalizeDegree(
      programDegree.toLowerCase(),
    );
    final bool degreeMismatch = normalizedStudentDegree.isNotEmpty &&
        normalizedProgramDegree.isNotEmpty &&
        normalizedStudentDegree != normalizedProgramDegree;

    final double germanGpa = _resolveStudentGermanGpa(studentProfile);
    final bool studentHasIelts = studentProfile['has_ielts'] as bool? ?? false;
    final double studentIeltsScore =
        (studentProfile['ielts_score'] as num?)?.toDouble() ?? 0.0;
    final bool studentHasToefl = studentProfile['has_toefl'] as bool? ?? false;
    final double studentToeflScore =
        (studentProfile['toefl_score'] as num?)?.toDouble() ?? 0.0;
    final bool studentHasMoi = studentProfile['has_moi'] as bool? ?? false;
    final String studentTargetMajor =
        (studentProfile['target_major'] as String? ?? '').toLowerCase().trim();
    final String studentLangPref =
        (studentProfile['language_preference'] as String? ?? 'English')
            .toLowerCase()
            .trim();
    final int gpaScore = _calculateGpaScore(
      germanGpa: germanGpa,
      programRequiredGpa: programRequiredGpa,
    );
    final int majorScore = _calculateMajorScore(
      studentTargetMajor: studentTargetMajor,
      programMajor: programMajor.toLowerCase(),
      programName: programName.toLowerCase(),
    );
    final int ieltsScore = _calculateIeltsScore(
      programRequiresIelts: programRequiresIelts,
      programMinIelts: programMinIelts,
      programAcceptsMoi: programAcceptsMoi,
      studentHasIelts: studentHasIelts,
      studentIeltsScore: studentIeltsScore,
      studentHasToefl: studentHasToefl,
      studentToeflScore: studentToeflScore,
      studentHasMoi: studentHasMoi,
    );
    final int langScore = _calculateLanguageScore(
      studentLangPref: studentLangPref,
      programLanguage: programLanguage.toLowerCase(),
    );
    final int completenessScore = _calculateCompletenessScore(
      studentProfile: studentProfile,
    );

    final int rawTotal =
        gpaScore + majorScore + ieltsScore + langScore + completenessScore;
    final int total = degreeMismatch
        ? 0
        : rawTotal.clamp(0, 100);

    return {
      'total': total,
      'label': getScoreLabel(total),
      'breakdown': {
        'gpa': {
          'score': gpaScore,
          'max': 35,
          'student_gpa': germanGpa,
          'german_gpa': germanGpa,
          'required_gpa': programRequiredGpa,
        },
        'major': {
          'score': majorScore,
          'max': 25,
          'student_major': studentProfile['target_major'],
          'program_major': programMajor,
        },
        'ielts': {
          'score': ieltsScore,
          'max': 15,
          'requires_ielts': programRequiresIelts,
          'min_ielts': programMinIelts,
          'student_ielts': studentIeltsScore,
        },
        'language': {
          'score': langScore,
          'max': 15,
          'student_pref': studentProfile['language_preference'],
          'program_lang': programLanguage,
        },
        'completeness': {
          'score': completenessScore,
          'max': 10,
          'has_transcripts': studentProfile['has_transcripts'] is String && (studentProfile['has_transcripts'] as String).isNotEmpty,
          'has_bachelor_cert': studentProfile['has_bachelor_cert'] is String && (studentProfile['has_bachelor_cert'] as String).isNotEmpty,
          'has_sop': studentProfile['has_sop'] is String && (studentProfile['has_sop'] as String).isNotEmpty,
          'has_cv': studentProfile['has_cv'] is String && (studentProfile['has_cv'] as String).isNotEmpty,
        },
        'intake': {
          'score': 0,
          'max': 0,
          'student_intake': studentProfile['intake'],
          'program_intake': programIntake,
        },
      },
    };
  }
}
