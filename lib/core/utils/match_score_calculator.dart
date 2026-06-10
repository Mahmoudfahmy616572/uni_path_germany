// ====================
// FILE: lib/core/utils/match_score_calculator.dart
// ====================
//
// الـ Matching Score بيتحسب من 100 نقطة موزعة كالآتي:
//
//  [35 pts] GPA
//  [25 pts] Target Major
//  [15 pts] IELTS / Language Certificate
//  [15 pts] Language of Instruction
//  [10 pts] Intake Semester
//
// القيمة الدنيا للـ score بعد الحسبة هي 0 — مش 10 زي زمان.
// لو الـ degree_level مش متطابق، الفانكشن بترجع 0 على طول (hard filter).

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
    required String programIntake,
    required String programLanguage,
    required String programDegree,
  }) {
    // ── 0. Degree Hard Filter ──────────────────────────────
    // لو الـ degree مش متطابق أصلاً → مش مناسب خالص
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
    final double studentGpa =
        (studentProfile['gpa'] as num?)?.toDouble() ?? 0.0;
    final double studentMaxGpa =
        (studentProfile['max_gpa'] as num?)?.toDouble() ?? 4.0;

    final bool studentHasIelts = studentProfile['has_ielts'] as bool? ?? false;
    final double studentIeltsScore =
        (studentProfile['ielts_score'] as num?)?.toDouble() ?? 0.0;
    final bool studentHasMoi = studentProfile['has_moi'] as bool? ?? false;

    final String studentTargetMajor =
        (studentProfile['target_major'] as String? ?? '').toLowerCase().trim();
    final String studentLangPref =
        (studentProfile['language_preference'] as String? ?? 'English')
            .toLowerCase()
            .trim();
    final String studentIntake = (studentProfile['intake'] as String? ?? '')
        .toLowerCase()
        .trim();

    int score = 0;

    // ── 1. GPA (35 نقطة) ──────────────────────────────────
    score += _calculateGpaScore(
      studentGpa: studentGpa,
      studentMaxGpa: studentMaxGpa,
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
      studentHasMoi: studentHasMoi,
    );

    // ── 4. Language of Instruction (15 نقطة) ──────────────
    score += _calculateLanguageScore(
      studentLangPref: studentLangPref,
      programLanguage: programLanguage.toLowerCase(),
    );

    // ── 5. Intake Semester (10 نقطة) ──────────────────────
    score += _calculateIntakeScore(
      studentIntake: studentIntake,
      programIntake: programIntake.toLowerCase(),
    );

    return score.clamp(0, 100);
  }

  // ─────────────────────────────────────────────────────────
  // 1. GPA Score — 35 نقطة
  // ─────────────────────────────────────────────────────────
  // الفكرة: بنحوّل GPA الطالب وبتاع البرنامج لنسبة مئوية
  // من الـ scale بتاعه عشان المقارنة تبقى fair.
  //
  //  ≥ required GPA             → 35 نقطة (مؤهل كامل)
  //  بين required-0.2 وrequired → 25 نقطة (قريب جداً، ممكن بـ waiver)
  //  بين required-0.5 وrequired-0.2 → 15 نقطة (ممكن بـ conditional)
  //  أقل من required - 0.5      → 0 نقطة (غير مؤهل)
  // ─────────────────────────────────────────────────────────
  static int _calculateGpaScore({
    required double studentGpa,
    required double studentMaxGpa,
    required double programRequiredGpa,
  }) {
    if (studentGpa <= 0 || programRequiredGpa <= 0) return 0;

    // normalize إلى scale 4.0 لو الطالب على scale مختلفة
    final double normalizedStudentGpa = studentMaxGpa > 0
        ? (studentGpa / studentMaxGpa) * 4.0
        : studentGpa;

    final double diff = normalizedStudentGpa - programRequiredGpa;

    if (diff >= 0) return 35; // مؤهل كامل
    if (diff >= -0.2) return 25; // قريب جداً
    if (diff >= -0.5) return 15; // قريب نسبياً
    return 0; // بعيد
  }

  // ─────────────────────────────────────────────────────────
  // 2. Major Score — 25 نقطة
  // ─────────────────────────────────────────────────────────
  // بنستخدم keyword mapping عشان نغطي حالات زي:
  //   - الطالب اختار "Computer Science & IT" والبرنامج اسمه "Computer Science"
  //   - الطالب اختار "Engineering" والبرنامج "Mechanical Engineering"
  //
  //  exact match                     → 25 نقطة
  //  keyword match (نفس الـ category) → 18 نقطة
  //  broad category match            → 10 نقطة
  //  مفيش match                      → 0 نقطة
  // ─────────────────────────────────────────────────────────
  static int _calculateMajorScore({
    required String studentTargetMajor,
    required String programMajor,
    required String programName,
  }) {
    if (studentTargetMajor.isEmpty) return 12; // مش حدد، نبقى محايدين

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
      return 18;
    }

    // Check program name as fallback
    if (programName.contains(studentTargetMajor) ||
        studentTargetMajor
            .split(' ')
            .any((word) => word.length > 3 && programMajor.contains(word))) {
      return 10;
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
    required bool studentHasMoi,
  }) {
    if (!programRequiresIelts) {
      // البرنامج مش بيطلب شهادة لغة → الكل بياخد الـ 15
      return 15;
    }

    // البرنامج بيطلب IELTS
    if (studentHasIelts) {
      if (studentIeltsScore >= programMinIelts) return 15; // مؤهل كامل
      if (studentIeltsScore >= programMinIelts - 0.5) return 8; // قريب
      return 3; // عنده IELTS بس تحت المطلوب بكتير
    }

    // الطالب معهوش IELTS — هل البرنامج بيقبل MOI؟
    if (programAcceptsMoi && studentHasMoi) return 10;

    return 0; // مش مؤهل للـ language requirement
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
  // 5. Intake Semester Score — 10 نقطة
  // ─────────────────────────────────────────────────────────
  // Program intake_type: 'summer', 'winter', 'both'
  // Student intake: 'summer semester', 'winter semester', 'both semesters'
  //
  // الـ normalization مهم جداً هنا عشان الـ DB values مختلفة.
  // ─────────────────────────────────────────────────────────
  static int _calculateIntakeScore({
    required String studentIntake,
    required String programIntake,
  }) {
    // normalize strings
    final String normStudent = _normalizeIntake(studentIntake);
    final String normProgram = _normalizeIntake(programIntake);

    if (normProgram == 'both' || normStudent == 'both') return 10;
    if (normProgram == normStudent) return 10;
    return 0;
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  // يحوّل "summer semester" → "summer"، "both semesters" → "both"، إلخ
  static String _normalizeIntake(String intake) {
    if (intake.contains('both')) return 'both';
    if (intake.contains('summer')) return 'summer';
    if (intake.contains('winter')) return 'winter';
    return intake.trim();
  }

  // يحوّل "bachelor's degree" → "bachelor"، "master's degree" → "master"، إلخ
  static String _normalizeDegree(String degree) {
    if (degree.contains('bachelor')) return 'bachelor';
    if (degree.contains('master')) return 'master';
    if (degree.contains('doctor') || degree.contains('phd')) return 'doctorate';
    return '';
  }

  // ─────────────────────────────────────────────────────────
  // Score Label — للـ UI
  // ─────────────────────────────────────────────────────────
  // بترجع نص وصفي بناءً على الـ score النهائي.
  // ─────────────────────────────────────────────────────────
  static String getScoreLabel(int score) {
    if (score >= 85) return 'Excellent Match';
    if (score >= 70) return 'Strong Match';
    if (score >= 55) return 'Good Match';
    if (score >= 40) return 'Fair Match';
    if (score >= 25) return 'Weak Match';
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
    required String programIntake,
    required String programLanguage,
    required String programDegree,
  }) {
    final double studentGpa =
        (studentProfile['gpa'] as num?)?.toDouble() ?? 0.0;
    final double studentMaxGpa =
        (studentProfile['max_gpa'] as num?)?.toDouble() ?? 4.0;
    final bool studentHasIelts = studentProfile['has_ielts'] as bool? ?? false;
    final double studentIeltsScore =
        (studentProfile['ielts_score'] as num?)?.toDouble() ?? 0.0;
    final bool studentHasMoi = studentProfile['has_moi'] as bool? ?? false;
    final String studentTargetMajor =
        (studentProfile['target_major'] as String? ?? '').toLowerCase().trim();
    final String studentLangPref =
        (studentProfile['language_preference'] as String? ?? 'English')
            .toLowerCase()
            .trim();
    final String studentIntake = (studentProfile['intake'] as String? ?? '')
        .toLowerCase()
        .trim();

    final int gpaScore = _calculateGpaScore(
      studentGpa: studentGpa,
      studentMaxGpa: studentMaxGpa,
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
      studentHasMoi: studentHasMoi,
    );
    final int langScore = _calculateLanguageScore(
      studentLangPref: studentLangPref,
      programLanguage: programLanguage.toLowerCase(),
    );
    final int intakeScore = _calculateIntakeScore(
      studentIntake: studentIntake,
      programIntake: programIntake.toLowerCase(),
    );

    final int total =
        (gpaScore + majorScore + ieltsScore + langScore + intakeScore).clamp(
          0,
          100,
        );

    return {
      'total': total,
      'label': getScoreLabel(total),
      'breakdown': {
        'gpa': {
          'score': gpaScore,
          'max': 35,
          'student_gpa': studentGpa,
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
        'intake': {
          'score': intakeScore,
          'max': 10,
          'student_intake': studentProfile['intake'],
          'program_intake': programIntake,
        },
      },
    };
  }
}
