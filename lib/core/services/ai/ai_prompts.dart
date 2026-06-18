class AiPrompts {
  static String _lang(String code) =>
      code == 'ar' ? '\nRespond in Arabic. Use formal academic Arabic language.\n' : '';

  static String _studentContext(Map<String, dynamic> p) {
    return '''
Student Profile:
- GPA: ${p['gpa'] ?? 'Not set'} / ${p['max_gpa'] ?? '4.0'}
- Target Major: ${p['target_major'] ?? 'Not set'}
- Degree Level: ${p['degree_level'] ?? 'Not set'}
- IELTS: ${p['has_ielts'] == true ? '${p['ielts_score'] ?? 'N/A'} (has IELTS)' : 'No IELTS'}
- TOEFL: ${p['has_toefl'] == true ? '${p['toefl_score'] ?? 'N/A'} (has TOEFL)' : 'No TOEFL'}
- MOI: ${p['has_moi'] == true ? 'Has MOI' : 'No MOI'}
- Language Preference: ${p['language_preference'] ?? 'Not set'}
- Target Intake: ${p['intake'] ?? 'Not set'}
- German Level: ${p['german_level'] ?? 'Not set'}
''';
  }

  static String _resources() {
    return '''
Useful Resources (mention relevant ones in your suggestions when applicable):
- DAAD (German Academic Exchange Service): https://www.daad.de/en/
- uni-assist (centralized application portal for many German universities): https://www.uni-assist.de/en/
- anabin (database for international degree recognition): https://anabin.kmk.org/
- DAAD database of accredited programs: https://www.daad.de/en/study-and-research-in-germany/
- For certificate legalization: check your country's German embassy website
- For German language tests: TestDaF (https://www.testdaf.de/), Goethe-Institut (https://www.goethe.de/)
''';
  }

  static String _priorityRule() {
    return '''
IMPORTANT — Priority Distribution Rules:
- At most ONE issue can be "high" per review.
- "high" = blocks admission (missing required document, wrong format, critical error). Takes 2-4+ weeks to fix.
- "medium" = significantly weakens the application. Takes 1-2 weeks to fix.
- "low" = minor polish / nice-to-have improvement. Takes 1-3 days to fix.
- If everything is critical, pick the single most important issue as "high" and label the rest "medium".
''';
  }

  // ─────────────────────────────────────────────────────
  //  PDF Document Review (for uploaded files)
  // ─────────────────────────────────────────────────────
  static String reviewDocumentWithPdf({
    required Map<String, dynamic> studentProfile,
    required String programName,
    required String docType,
    required String title,
    String languageCode = 'en',
  }) {
    final docSpecific = _docSpecificGuidance(docType, title);
    return '''
You are a German university admissions officer reviewing an uploaded document in detail.

${_studentContext(studentProfile)}

Document: $title (type: $docType)
Target Program: $programName

${_resources()}

$docSpecific

${_priorityRule()}

Review this document against the student's profile and the program requirements. For each issue:
1. Compare the document content with what German universities actually require for this type of document.
2. Consider the student's background (GPA, major, language scores) when making suggestions.
3. Give an estimated time frame to fix each issue (e.g., "Takes 1-2 weeks", "Same day fix", "2-4 weeks if legalization needed").
4. Embed the time estimate at the START of the suggestion text in parentheses.

Format as JSON array:
[
  {
    "issue": "string — exactly what is wrong",
    "severity": "high|medium|low — see priority rules above",
    "suggestion": "string — "(X-Y weeks/days):" then exactly what to change, how, and include relevant links from the resources above if helpful"
  }
]

Example:
{"issue":"GPA is stated without the grading scale","severity":"high","suggestion":"(1-2 days): Add the grading scale next to your GPA (e.g., '3.1 / 4.0'). Without the scale, German admissions officers cannot evaluate your academic standing. Use the Bavarian formula to convert if needed: German GPA = 1 + 3 × (4.0 - achieved) / (4.0 - 1.0). See anabin (https://anabin.kmk.org/) for your country's classification."}

${_lang(languageCode)}Return ONLY the JSON array, no markdown, no code fences.
''';
  }

  static String _docSpecificGuidance(String docType, String title) {
    switch (docType) {
      case 'transcripts':
        return '''
Guidance for Academic Transcripts:
- Check grading scale (is it 4.0, 5.0, 100%, or other?).
- Verify the applicant's GPA is clearly stated or calculable from grades.
- Look for total credit hours / ECTS equivalence.
- Note if the transcript includes individual course grades or just a final CGPA.
- German universities require a detailed Transcript of Records, not just a grade summary.
- Check if translation is needed (German or English).
- Check for apostille / legalization requirements based on the country.
''';
      case 'bachelor_cert':
        return '''
Guidance for Bachelor's Certificate / Degree:
- Verify the degree title and field of study match the application.
- Check if the university is recognized (Hochschulzugang).
- Look for graduation date — must be before program start.
- Check if diploma supplement or transcript is also provided (both needed).
- Note legalization requirements (apostille for Hague countries, embassy legalization for others).
- Verify the name on the certificate matches the application.
''';
      case 'sop':
        return '''
Guidance for SOP / Motivation Letter:
- Check if the letter is tailored to THIS specific program and university (not generic).
- Look for specific professor names, research groups, or modules mentioned.
- Verify the applicant explains WHY Germany and WHY this university.
- Check for concrete examples and experiences (not just "I am passionate").
- Evaluate structure: intro → background → why this program → goals → conclusion.
- A strong SOP is 400-600 words, focused, and personal.
- Check for any irrelevant content, spelling errors, or formatting issues.
''';
      case 'cv':
        return '''
Guidance for CV / Resume:
- German-style CV (Lebenslauf) should be in reverse chronological order.
- Check for tabular format (personal info, education, work, skills).
- Verify dates are realistic and consistent (no future dates).
- Check that GPA is presented WITH the scale (e.g., "3.1/4.0" not just "3.1").
- Look for relevant technical skills, languages (with levels), and certifications.
- CV should be 1-2 pages, clear and professional.
- Photo is optional in Germany (check if included).
- Check if the CV addresses the specific program requirements.
''';
      case 'language_cert':
        return '''
Guidance for Language Certificate:
- Verify the certificate type matches program requirements (IELTS Academic, TOEFL iBT, TestDaF, DSH, Goethe).
- Check scores against typical German requirements (IELTS 6.0-6.5, TOEFL 80-90, TestDaF 4×4).
- Verify the certificate is not expired (IELTS/TOEFL valid 2 years).
- Check the applicant's name matches their other documents.
- For MOI: verify it explicitly states the medium of instruction was English/German.
''';
      default:
        return '';
    }
  }

  // ─────────────────────────────────────────────────────
  //  Text Document Review (for pasted content)
  // ─────────────────────────────────────────────────────
  static String documentReview({
    required Map<String, dynamic> studentProfile,
    required String programName,
    required String docType,
    required String documentContent,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions officer reviewing a document.

${_studentContext(studentProfile)}

Document Type: $docType
Target Program: $programName

${_resources()}

Document Content:
$documentContent

${_priorityRule()}

Compare this document against typical German university requirements. Give 3-5 specific improvement suggestions. Embed the time estimate at the start of each suggestion. Include relevant resource links when helpful.

Format as JSON array:
[
  {
    "issue": "string",
    "severity": "high|medium|low",
    "suggestion": "string — "(X-Y weeks/days):" then the advice"
  }
]

${_lang(languageCode)}Return ONLY the JSON array, no markdown, no code fences.
''';
  }

  // ─────────────────────────────────────────────────────
  //  Document Suggestions (all documents aggregated)
  // ─────────────────────────────────────────────────────
  static String documentSuggestions({
    required Map<String, dynamic> studentProfile,
    required Map<String, dynamic> programDetails,
    required Map<String, dynamic> uploadStatus,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions document specialist analyzing an applicant's complete document set.

${_studentContext(studentProfile)}

Program Details:
- Name: ${programDetails['name'] ?? 'N/A'}
- Major: ${programDetails['major'] ?? 'N/A'}
- Degree: ${programDetails['degree'] ?? 'N/A'}
- Required GPA: ${programDetails['required_gpa'] ?? 'N/A'}
- Requires IELTS: ${programDetails['requires_ielts'] == true ? 'Yes (min: ${programDetails['min_ielts']})' : 'No'}
- Accepts MOI: ${programDetails['accepts_moi'] == true ? 'Yes' : 'No'}
- Language: ${programDetails['language'] ?? 'N/A'}

${_resources()}

Uploaded Documents Status:
- Transcripts: ${uploadStatus['has_transcripts'] == true ? 'Uploaded' : 'Missing'}
- Bachelor Certificate: ${uploadStatus['has_bachelor_cert'] == true ? 'Uploaded' : 'Missing'}
- SOP / Motivation Letter: ${uploadStatus['has_sop'] == true ? 'Uploaded' : 'Missing'}
- CV / Resume: ${uploadStatus['has_cv'] == true ? 'Uploaded' : 'Missing'}
- Language Certificate (IELTS/MOI/TestDaF/Goethe): ${uploadStatus['has_language_cert'] == true ? 'Uploaded' : 'Missing'}

${_priorityRule()}

For each document:
- If uploaded: give 2-3 specific tips to tailor it for this German university program. Embed time estimate in each tip.
- If missing: explain why it matters and what to include (1-2 tips). Embed time estimate.

Compare the uploaded document set against the program requirements. Identify gaps:
- Is the language certificate type appropriate for the program language?
- Is the GPA from the transcript competitive against the program's required GPA?
- Is the CV/SOP tailored to this specific program, or generic?

Format as JSON array:
[
  {
    "doc_type": "transcripts|bachelor_cert|sop|cv|language_cert",
    "status": "uploaded|missing",
    "title": "string",
    "tips": ["(X-Y units): tip1", "(X-Y units): tip2"],
    "importance": "high|medium|low — at most ONE per status group"
  }
]

${_lang(languageCode)}Return ONLY the JSON array, no markdown, no code fences.
''';
  }

  // ─────────────────────────────────────────────────────
  //  Match Score Improvement Suggestions
  // ─────────────────────────────────────────────────────
  static String improvementSuggestions({
    required Map<String, dynamic> studentProfile,
    required Map<String, dynamic> programDetails,
    required Map<String, dynamic> breakdown,
    String languageCode = 'en',
  }) {
    return '''
You are a German university admissions advisor. Analyze this student's profile against a program and give 3-5 specific, actionable suggestions to improve their match score.

${_studentContext(studentProfile)}

Program Details:
- Name: ${programDetails['name'] ?? 'N/A'}
- Major: ${programDetails['major'] ?? 'N/A'}
- Degree: ${programDetails['degree'] ?? 'N/A'}
- Required GPA: ${programDetails['required_gpa'] ?? 'N/A'}
- Requires IELTS: ${programDetails['requires_ielts'] == true ? 'Yes (min: ${programDetails['min_ielts']})' : 'No'}
- Accepts MOI: ${programDetails['accepts_moi'] == true ? 'Yes' : 'No'}
- Language: ${programDetails['language'] ?? 'N/A'}
- Intake: ${programDetails['intake'] ?? 'N/A'}

${_resources()}

Match Score Breakdown (out of 100):
${_breakdownToString(breakdown)}

Important notes:
- Only the student can change their profile data (GPA, major, etc.)
- The student cannot change program requirements
- The student can upload documents (CV, SOP, transcripts, certificates)
- If English is needed, check if the student needs IELTS or MOI

Compare the student profile against each breakdown category. For the lowest-scoring categories, identify the fastest wins (short time, high impact).

For each suggestion:
1. **Title** - short 3-5 word action
2. **Category** - which breakdown category it affects
3. **Impact** - "+X points" estimate
4. **Action** - what the student should do, including time estimate (e.g., "Take IELTS exam (1-2 months prep)") and relevant resource links
5. **Priority** - high/medium/low — at most ONE "high"

Format as JSON array:
[
  {
    "title": "string",
    "category": "gpa|major|ielts|language|intake|documents",
    "impact": "string like +5 points",
    "action": "string — include time estimate and resource link if helpful",
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

  // ─────────────────────────────────────────────────────
  //  Document Generation (legacy)
  // ─────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────
  //  CV Generation
  // ─────────────────────────────────────────────────────
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
- Format as a German-style tabular CV (Lebenslauf) in reverse chronological order
- Include sections: Personal Data, Education, Work Experience, Skills, Languages, Interests
- For GPA: always include the scale (e.g., "3.1 / 4.0")
- Use clear markdown formatting (headers, bold, lists)
- Tailor content specifically for $programName at $universityName
- Keep to 1-2 pages worth of content
- Be professional and precise — German universities value clarity
- DO NOT include any future dates or ongoing projects without end dates
- Ensure all dates are realistic and consistent

${_lang(languageCode)}Return ONLY the CV content as markdown, no extra commentary.
''';
  }

  // ─────────────────────────────────────────────────────
  //  SOP Generation
  // ─────────────────────────────────────────────────────
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
- Structure: Introduction → Academic Background → Why This Program → Why Germany → Career Goals → Conclusion
- Explain why the student chose Germany and THIS specific university — be specific (name professors, modules, labs)
- Connect the student's background to the program's strengths
- Include concrete examples from the student's experience (projects, research, work)
- Avoid generic statements like "I am passionate" — demonstrate through examples
- Keep to 400-600 words
- Professional but personal tone
- Use clear markdown formatting

Program Highlights to emphasize:
$programHighlights

${_lang(languageCode)}Return ONLY the letter as markdown, no extra commentary.
''';
  }
}
