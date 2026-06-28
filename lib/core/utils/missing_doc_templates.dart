/// Static templates for missing documents.
/// Replaces Gemini API calls for missing docs — saves usage and gives reliable advice.
class MissingDocTemplates {
  /// Returns a single template for a specific doc type (1 map, not all 5).
  static Map<String, dynamic> suggestionForDocType(
      String docType, Map<String, dynamic> studentProfile) {
    switch (docType) {
      case 'transcripts':
        return _transcripts();
      case 'bachelor_cert':
        return _bachelorCert();
      case 'sop':
        return _sop(studentProfile);
      case 'cv':
        return _cv();
      case 'language_cert':
        return _languageCert(studentProfile);
      case 'german_cert':
        return _germanCert();
      default:
        return {'doc_type': docType, 'status': 'missing', 'title': 'Document', 'tips': []};
    }
  }

  static List<Map<String, dynamic>> getSuggestions(
      Map<String, dynamic> studentProfile) {
    final hasIelts = studentProfile['has_ielts'] == true;
    final hasToefl = studentProfile['has_toefl'] == true;
    final hasMoi = studentProfile['has_moi'] == true;
    final needsLang = hasIelts || hasToefl || hasMoi;

    final hasGerman = studentProfile['has_german_cert'] == true;

    return [
      _transcripts(),
      _bachelorCert(),
      _sop(studentProfile),
      _cv(),
      if (needsLang) _languageCert(studentProfile),
      if (hasGerman) _germanCert(),
    ];
  }

  static Map<String, dynamic> _transcripts() {
    return {
      'doc_type': 'transcripts',
      'status': 'missing',
      'title': 'Academic Transcripts',
      'importance': 'high',
      'tips': [
        'Request a detailed Transcript of Records from your university showing ALL courses taken, individual grades, credit hours, and the grading scale.',
        'If your university uses a percentage system, include the conversion key. German universities need to understand your actual performance course-by-course.',
        'Have the transcript officially translated into German or English by a certified translator.',
        'For non-EU countries: get the transcript legalized (apostille or embassy attestation depending on your country).',
      ],
    };
  }

  static Map<String, dynamic> _bachelorCert() {
    return {
      'doc_type': 'bachelor_cert',
      'status': 'missing',
      'title': 'Bachelor Certificate',
      'importance': 'high',
      'tips': [
        'Upload your graduation certificate/diploma showing the degree awarded, field of study, and graduation date.',
        'Include a Diploma Supplement if your university issues one — it helps German universities evaluate your degree faster.',
        'Have the certificate officially translated into German or English.',
        'Check if your country needs apostille (Hague Convention members) or embassy legalization for Germany — this can take 2-4 weeks.',
      ],
    };
  }

  static Map<String, dynamic> _sop(Map<String, dynamic> p) {
    return {
      'doc_type': 'sop',
      'status': 'missing',
      'title': 'SOP / Motivation Letter',
      'importance': 'high',
      'tips': [
        'Write 400-600 words explaining WHY this specific program and university — name professors, research groups, or modules that interest you.',
        'Structure: Introduction → Academic Background → Why Germany/This University → Career Goals → Conclusion.',
        'Include concrete examples from your projects, thesis, or work experience. Avoid generic phrases like "I am passionate."',
        'Explain how your background prepares you for THIS program and what you will contribute.',
        'Have someone review for grammar, clarity, and tone — German universities value precision.',
      ],
    };
  }

  static Map<String, dynamic> _cv() {
    return {
      'doc_type': 'cv',
      'status': 'missing',
      'title': 'CV / Resume',
      'importance': 'medium',
      'tips': [
        'Use a German-style tabular CV (Lebenslauf) in reverse chronological order — personal info, education, work, skills, languages.',
        'Include your GPA with the scale clearly stated (e.g., "3.1 / 4.0"). German admissions officers need the scale to evaluate.',
        'List technical skills, programming languages, tools, and frameworks relevant to your target program.',
        'Add language proficiencies with official levels (e.g., "English C1", "German A2").',
        'Keep to 1-2 pages. No photo required in Germany (optional). Ensure all dates are realistic — no future dates.',
      ],
    };
  }

  static Map<String, dynamic> _languageCert(Map<String, dynamic> p) {
    final hasIelts = p['has_ielts'] == true;
    final hasMoi = p['has_moi'] == true;

    String certTip;
    if (hasMoi) {
      certTip =
          'Upload your Medium of Instruction (MOI) certificate from your university. Some programs may still prefer IELTS/TOEFL — check program requirements.';
    } else if (hasIelts) {
      certTip =
          'Upload your IELTS Test Report Form (TRF). Ensure it is valid (less than 2 years old) and meets the program minimum (typically 6.0-6.5 overall).';
    } else {
      certTip =
          'Upload your TOEFL iBT score report. Ensure it is valid (less than 2 years old) and meets the program minimum (typically 80-90).';
    }

    return {
      'doc_type': 'language_cert',
      'status': 'missing',
      'title': 'Language Certificate',
      'importance': 'high',
      'tips': [
        certTip,
        'If you have both IELTS and TOEFL, upload the one with the higher score.',
        'For German-taught programs: TestDaF (4×4) or DSH-2 is typically required. Goethe B2/C1 may also be accepted — check program page.',
      ],
    };
  }

  static Map<String, dynamic> _germanCert() {
    return {
      'doc_type': 'german_cert',
      'status': 'missing',
      'title': 'German Language Certificate',
      'importance': 'medium',
      'tips': [
        'Consider taking a German language certificate (TestDaF, Goethe, DSH, Telc, or ÖSD) if the program requires German proficiency.',
        'Most German-taught programs require B2 or C1 level. TestDaF level 4 in all sections (TDN 4) is widely accepted.',
        'Goethe-Zertifikat B2/C1 is valid indefinitely and recognized by most German universities.',
      ],
    };
  }
}
