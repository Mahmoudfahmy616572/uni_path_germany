class AiPrompts {
  static String _lang(String code) =>
      code == 'ar' ? '\nRespond in Arabic. Use formal Arabic language.\n' : '';

  static String improvementSuggestions({
    required Map<String, dynamic> studentProfile,
    required Map<String, dynamic> programDetails,
    required Map<String, dynamic> breakdown,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions advisor. Analyze this student's profile against a program and give 3-5 specific, actionable suggestions to improve their match score.

Student Profile:
- GPA: ${studentProfile['gpa'] ?? 'Not set'} / ${studentProfile['max_gpa'] ?? '4.0'}
- Target Major: ${studentProfile['target_major'] ?? 'Not set'}
- Degree Level: ${studentProfile['degree_level'] ?? 'Not set'}
- IELTS: ${studentProfile['has_ielts'] == true ? '${studentProfile['ielts_score'] ?? 'N/A'} (has IELTS)' : 'No IELTS'}
- MOI: ${studentProfile['has_moi'] == true ? 'Has MOI' : 'No MOI'}
- Language Preference: ${studentProfile['language_preference'] ?? 'Not set'}
- Target Intake: ${studentProfile['intake'] ?? 'Not set'}

Program Details:
- Name: ${programDetails['name'] ?? 'N/A'}
- Major: ${programDetails['major'] ?? 'N/A'}
- Degree: ${programDetails['degree'] ?? 'N/A'}
- Required GPA: ${programDetails['required_gpa'] ?? 'N/A'}
- Requires IELTS: ${programDetails['requires_ielts'] == true ? 'Yes (min: ${programDetails['min_ielts']})' : 'No'}
- Accepts MOI: ${programDetails['accepts_moi'] == true ? 'Yes' : 'No'}
- Language: ${programDetails['language'] ?? 'N/A'}
- Intake: ${programDetails['intake'] ?? 'N/A'}

Match Score Breakdown (out of 100):
${_breakdownToString(breakdown)}

Important notes:
- Only the student can change their profile data (GPA, major, etc.)
- The student cannot change program requirements
- The student can upload documents (CV, SOP, transcripts, certificates)
- If English is needed, check if the student needs IELTS or MOI

For each suggestion:
1. **Title** - short 3-5 word action
2. **Category** - which breakdown category it affects
3. **Impact** - "+X points" estimate
4. **Action** - what the student should do
5. **Priority** - high/medium/low

Format as JSON array with this exact structure:
[
  {
    "title": "string",
    "category": "gpa|major|ielts|language|intake|documents",
    "impact": "string like +5 points",
    "action": "string",
    "priority": "high|medium|low"
  }
]

${_lang(languageCode)}Return ONLY the JSON array, no markdown, no code fences.
''';
  }

  static String _breakdownToString(Map<String, dynamic> breakdown) {
    final buf = StringBuffer();
    for (final entry in breakdown.entries) {
      buf.writeln(
        '  - ${entry.key}: ${entry.value['score']}/${entry.value['max']}',
      );
    }
    return buf.toString();
  }

  static String documentReview({
    required String programName,
    required String docType,
    required String documentContent,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions officer. Review this $docType for the "$programName" program and give feedback.

Document content:
$documentContent

Give 3-5 specific improvement suggestions. Format as JSON array:
[
  {
    "issue": "string",
    "severity": "high|medium|low",
    "suggestion": "string"
  }
]

${_lang(languageCode)}Return ONLY the JSON array, no markdown, no code fences.
''';
  }

  static String documentSuggestions({
    required Map<String, dynamic> studentProfile,
    required Map<String, dynamic> programDetails,
    required Map<String, dynamic> uploadStatus,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions document specialist. Analyze this student's application documents and give specific advice to improve each one.

Student Profile:
- Name: ${studentProfile['username'] ?? 'Student'}
- GPA: ${studentProfile['gpa'] ?? 'Not set'} / ${studentProfile['max_gpa'] ?? '4.0'}
- Target Major: ${studentProfile['target_major'] ?? 'Not set'}
- Degree Level: ${studentProfile['degree_level'] ?? 'Not set'}
- IELTS: ${studentProfile['has_ielts'] == true ? '${studentProfile['ielts_score']} (has IELTS)' : 'No IELTS'}
- MOI: ${studentProfile['has_moi'] == true ? 'Has MOI' : 'No MOI'}
- Language Preference: ${studentProfile['language_preference'] ?? 'Not set'}
- Target Intake: ${studentProfile['intake'] ?? 'Not set'}

Program Details:
- Name: ${programDetails['name'] ?? 'N/A'}
- Major: ${programDetails['major'] ?? 'N/A'}
- Degree: ${programDetails['degree'] ?? 'N/A'}
- Required GPA: ${programDetails['required_gpa'] ?? 'N/A'}
- Requires IELTS: ${programDetails['requires_ielts'] == true ? 'Yes (min: ${programDetails['min_ielts']})' : 'No'}
- Accepts MOI: ${programDetails['accepts_moi'] == true ? 'Yes' : 'No'}
- Language: ${programDetails['language'] ?? 'N/A'}

Uploaded Documents Status:
- Transcripts: ${uploadStatus['has_transcripts'] == true ? 'Uploaded' : 'Missing'}
- Bachelor Certificate: ${uploadStatus['has_bachelor_cert'] == true ? 'Uploaded' : 'Missing'}
- SOP / Motivation Letter: ${uploadStatus['has_sop'] == true ? 'Uploaded' : 'Missing'}
- CV / Resume: ${uploadStatus['has_cv'] == true ? 'Uploaded' : 'Missing'}
- Language Certificate (IELTS/MOI/TestDaF/Goethe): ${uploadStatus['has_language_cert'] == true ? 'Uploaded' : 'Missing'}

For each document the student HAS uploaded, give 2-3 specific tips to tailor it for this German university program.
For each document the student HAS NOT uploaded, explain why it matters and what to include.

Format as JSON array:
[
  {
    "doc_type": "transcripts|bachelor_cert|sop|cv|language_cert",
    "status": "uploaded|missing",
    "title": "string - short document name",
    "tips": ["tip1", "tip2", "tip3"],
    "importance": "high|medium|low"
  }
]

${_lang(languageCode)}Return ONLY the JSON array, no markdown, no code fences.
''';
  }

  static String documentGeneration({
    required String programName,
    required String universityName,
    required String degreeType,
    required String major,
    required String studentName,
    required String studentBackground,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions consultant. Generate a tailored $degreeType application document for "$programName" at "$universityName".

Student: $studentName
Background: $studentBackground
Major: $major

Generate a professional document optimized for this specific program. Return as plain text with markdown formatting only (no JSON).
${_lang(languageCode)}''';
  }

  static String cvGeneration({
    required String programName,
    required String universityName,
    required String major,
    required String studentName,
    required String studentBackground,
    required String targetDegree,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions consultant. Generate a professional **CV (Lebenslauf)** for a German master's application.

Student: $studentName
Background: $studentBackground
Target Program: $programName at $universityName
Target Degree: $targetDegree
Major: $major

Rules:
- Format as a German-style tabular CV (Lebenslauf)
- Include sections: Personal Data, Education, Work Experience, Skills, Interests
- Use clear markdown formatting (headers, bold, lists)
- Tailor content specifically for $programName at $universityName
- Keep to 1-2 pages worth of content
- Be professional and precise — German universities value clarity

${_lang(languageCode)}Return ONLY the CV content as markdown, no extra commentary.
''';
  }

  static String sopGeneration({
    required String programName,
    required String universityName,
    required String degreeType,
    required String major,
    required String studentName,
    required String studentBackground,
    required String programHighlights,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions consultant. Generate a compelling **Motivation Letter (SOP)** for a German university application.

Student: $studentName
Background: $studentBackground
Target Program: $programName at $universityName
Degree: $degreeType
Major: $major
Program Highlights: $programHighlights

Rules:
- Format as a formal business letter
- Structure: Introduction → Academic Background → Why This Program → Career Goals → Conclusion
- Explain why the student chose Germany and this specific university
- Connect the student's background to the program's strengths
- Keep to 400-600 words
- Professional but personal tone
- Use clear markdown formatting

Program Highlights to emphasize:
$programHighlights

${_lang(languageCode)}Return ONLY the letter as markdown, no extra commentary.
''';
  }
}
