import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../domain/entities/university_entity.dart';
import 'ai_prompts.dart';

class GeminiService {
  final Dio _dio;
  final String? _serverUrl;
  final String? _apiKey;

  GeminiService({String? serverUrl, String? apiKey})
      : _serverUrl = serverUrl ??
            const String.fromEnvironment('SERVER_URL', defaultValue: ''),
        _apiKey = apiKey ??
            const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  bool get _useServer => _serverUrl != null && _serverUrl.isNotEmpty;

  String get _baseUrl => _useServer
      ? _serverUrl!
      : 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash';

  Future<String> _callGemini(String prompt,
      {double temperature = 0.4, int maxOutputTokens = 8192}) async {
    return _retryOnRateLimit(() async {
      if (_useServer) {
        try {
          final response = await _dio.post('$_serverUrl/api/ai/chat',
              data: {
                'prompt': prompt,
                'temperature': temperature,
                'maxOutputTokens': maxOutputTokens,
              });
          return response.data['text'] as String? ?? '';
        } on DioException catch (e) {
          final code = e.response?.statusCode ?? 0;
          if ((code == 429 || code == 503) && (_apiKey != null && _apiKey.isNotEmpty)) {
            // fall through to direct Gemini API
          } else {
            rethrow;
          }
        }
      }

      if (_apiKey == null || _apiKey.isEmpty) {
        throw Exception(
            'No GEMINI_API_KEY or SERVER_URL set. Configure one in .env');
      }

      final response = await _dio.post(
        '$_baseUrl:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {'parts': [{'text': prompt}]}
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxOutputTokens,
          },
        },
      );
      return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          '';
    });
  }

  Future<String> _callGeminiWithPdf(
      String prompt, Uint8List pdfBytes, String mimeType) async {
    return _callGeminiWithMultiplePdfs(prompt, [
      {'bytes': pdfBytes, 'mimeType': mimeType, 'filename': 'document.pdf'},
    ]);
  }

  /// Send a prompt alongside one or more PDF files to Gemini.
  Future<String> _callGeminiWithMultiplePdfs(
    String prompt,
    List<Map<String, dynamic>> files,
  ) async {
    return _retryOnRateLimit(() async {
      if (_useServer) {
        try {
          final formData = FormData.fromMap({'prompt': prompt});
          for (int i = 0; i < files.length; i++) {
            formData.files.add(MapEntry(
              'file$i',
              MultipartFile.fromBytes(
                files[i]['bytes'] as Uint8List,
                filename: files[i]['filename'] as String? ?? 'document_$i.pdf',
                contentType:
                    DioMediaType.parse(files[i]['mimeType'] as String? ?? 'application/pdf'),
              ),
            ));
          }
          final response =
              await _dio.post('$_serverUrl/api/ai/chat-with-pdf', data: formData);
          return response.data['text'] as String? ?? '';
        } on DioException catch (e) {
          final code = e.response?.statusCode ?? 0;
          if ((code == 429 || code == 503) && (_apiKey != null && _apiKey.isNotEmpty)) {
            // fall through to direct Gemini API
          } else {
            rethrow;
          }
        }
      }

      if (_apiKey == null || _apiKey.isEmpty) {
        throw Exception(
            'No GEMINI_API_KEY or SERVER_URL set. Configure one in .env');
      }

      final response = await _dio.post(
        '$_baseUrl:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                ...files.map((f) => {
                      'inlineData': {
                        'mimeType':
                            f['mimeType'] as String? ?? 'application/pdf',
                        'data': base64Encode(f['bytes'] as Uint8List),
                      }
                    }),
              ]
            }
          ],
        },
      );
      return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          '';
    });
  }

  /// Retry on 429 (Rate Limit) with exponential backoff up to 5 attempts
  Future<T> _retryOnRateLimit<T>(Future<T> Function() fn) async {
    const maxRetries = 5;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await fn();
      } on DioException catch (e) {
        if (attempt < maxRetries - 1 &&
            e.type == DioExceptionType.badResponse &&
            (e.response?.statusCode == 429 || e.response?.statusCode == 503)) {
          final delay = Duration(seconds: 5 * (1 << attempt) + Random().nextInt(6));
          await Future.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Rate limit retry exhausted');
  }

  Future<List<Map<String, dynamic>>> getUniversityRecommendations({
    required Map<String, dynamic> studentProfile,
  }) async {
    final prompt = AiPrompts.universityRecommendations(studentProfile);
    final text = await _callGemini(prompt, temperature: 0.4);
    final result = _parseJsonResponse(text);
    if (result.isEmpty && text != '[]') {
      throw Exception('Recommendation parse failed');
    }
    return result;
  }

  Future<String> germanPractice(String message) async {
    final prompt = AiPrompts.germanPractice(message);
    return _callGemini(prompt, temperature: 0.5);
  }

  Future<List<Map<String, dynamic>>> getImprovementSuggestions({
    required Map<String, dynamic> studentProfile,
    required Map<String, dynamic> programDetails,
    required Map<String, dynamic> breakdown,
    String languageCode = 'en',
  }) async {
    final prompt = AiPrompts.improvementSuggestions(
      studentProfile: studentProfile,
      programDetails: programDetails,
      breakdown: breakdown,
      languageCode: languageCode,
    );
    final text = await _callGemini(prompt);
    final result = _parseJsonResponse(text);
    if (result.isEmpty && text != '[]') {
      final preview = text.length > 200
          ? '${text.substring(0, 100)}...[${text.length} chars]...${text.substring(text.length - 100)}'
          : text;
      throw Exception('Improve parse failed. Text: $preview');
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> reviewDocument({
    required Map<String, dynamic> studentProfile,
    required String programName,
    required String docType,
    required String documentContent,
    String languageCode = 'en',
  }) async {
    final prompt = AiPrompts.documentReview(
      studentProfile: studentProfile,
      programName: programName,
      docType: docType,
      documentContent: documentContent,
      languageCode: languageCode,
    );
    final text = await _callGemini(prompt);
    final result = _parseJsonResponse(text);
    if (result.isEmpty && text != '[]') {
      throw Exception('Gemini: $text');
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getDocumentSuggestions({
    required Map<String, dynamic> studentProfile,
    required Map<String, dynamic> programDetails,
    required Map<String, dynamic> uploadStatus,
    String languageCode = 'en',
  }) async {
    final prompt = AiPrompts.documentSuggestions(
      studentProfile: studentProfile,
      programDetails: programDetails,
      uploadStatus: uploadStatus,
      languageCode: languageCode,
    );
    final text = await _callGemini(prompt);
    final result = _parseJsonResponse(text);
    if (result.isEmpty && text != '[]') {
      final preview = text.length > 200
          ? '${text.substring(0, 100)}...[${text.length} chars]...${text.substring(text.length - 100)}'
          : text;
      throw Exception('DocSuggest parse failed. Text: $preview');
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> reviewDocumentWithPdf({
    required Map<String, dynamic> studentProfile,
    required String programName,
    required String docType,
    required String title,
    required Uint8List pdfBytes,
    String mimeType = 'application/pdf',
    String languageCode = 'en',
  }) async {
    final prompt = AiPrompts.reviewDocumentWithPdf(
      studentProfile: studentProfile,
      programName: programName,
      docType: docType,
      title: title,
      languageCode: languageCode,
    );

    final text = await _callGeminiWithPdf(prompt, pdfBytes, mimeType);
    final result = _parseJsonResponse(text);
    if (result.isEmpty && text != '[]') {
      throw Exception(
          'PDF review parse failed. Text: ${text.length > 200 ? text.substring(0, 200) : text}');
    }
    return result;
  }

  Future<String> generateDocument({
    required String programName,
    required String universityName,
    required String degreeType,
    required String major,
    required String studentName,
    required String studentBackground,
    String languageCode = 'en',
  }) async {
    final prompt = AiPrompts.documentGeneration(
      programName: programName,
      universityName: universityName,
      degreeType: degreeType,
      major: major,
      studentName: studentName,
      studentBackground: studentBackground,
      languageCode: languageCode,
    );
    return await _callGemini(prompt);
  }

  Future<String> generateCv({
    required String programName,
    required String universityName,
    required String major,
    required String studentName,
    required String studentBackground,
    required String targetDegree,
    String languageCode = 'en',
    Uint8List? transcriptPdf,
    Uint8List? bachelorCertPdf,
    Uint8List? existingCvPdf,
  }) async {
    String prompt = AiPrompts.cvGeneration(
      programName: programName,
      universityName: universityName,
      major: major,
      studentName: studentName,
      studentBackground: studentBackground,
      targetDegree: targetDegree,
      languageCode: languageCode,
    );

    final files = <Map<String, dynamic>>[];
    bool hasDocs = false;
    if (transcriptPdf != null) {
      if (!hasDocs) { prompt = _prependDocExtraction(prompt, 'CV'); hasDocs = true; }
      files.add({
        'bytes': transcriptPdf, 'mimeType': 'application/pdf', 'filename': 'transcript.pdf'
      });
    }
    if (bachelorCertPdf != null) {
      if (!hasDocs) { prompt = _prependDocExtraction(prompt, 'CV'); hasDocs = true; }
      files.add({
        'bytes': bachelorCertPdf, 'mimeType': 'application/pdf', 'filename': 'bachelor_cert.pdf'
      });
    }
    if (existingCvPdf != null) {
      if (!hasDocs) { prompt = _prependDocExtraction(prompt, 'CV'); hasDocs = true; }
      files.add({
        'bytes': existingCvPdf, 'mimeType': 'application/pdf', 'filename': 'existing_cv.pdf'
      });
    }

    if (files.isNotEmpty) {
      return await _callGeminiWithMultiplePdfs(prompt, files);
    }
    return await _callGemini(prompt);
  }

  /// Prepend instructions telling Gemini to extract data from attached PDFs
  /// then generate a rich, detailed document.
  String _prependDocExtraction(String originalPrompt, String docType) {
    return '''
IMPORTANT INSTRUCTION — Student documents are attached as PDFs.

Read ALL attached documents carefully and extract comprehensive data about the student:
- Academic Transcript: GPA, grading scale, university name, degree/major, all course names and grades, credit hours, graduation date, any honors
- Bachelor Certificate: full legal name, degree title, university, graduation date
- Existing CV (if attached): work experience with dates and employers, skills, projects, certifications, languages, achievements, and ALL links (GitHub, LinkedIn, portfolio, project URLs, social media)

Priority order when information overlaps: Academic Transcript (most reliable) > Bachelor Certificate > Existing CV > Background text below.

Then generate a RICH, DETAILED $docType. Requirements:
- Base everything on the extracted document data — this is your primary source
- EXPAND on the data you find: describe course content, elaborate on work responsibilities and achievements, add context to projects
- Create a comprehensive 1-2 page document with substantive content in every section
- For each work experience entry, include 2-4 bullet points describing responsibilities and achievements
- For education, describe relevant coursework, projects, and academic achievements
- Include all skills, languages, and certifications found in the documents
- When citing GPA, always include the grading scale from the transcript
- If the existing CV contains a phone/email/address, use those; otherwise omit
- CRITICAL — Extract and preserve ALL links/URLs from the existing CV (GitHub profile, LinkedIn profile, project repositories, portfolio website, social media, etc.). Include them under the relevant sections (e.g., under Projects add the project repo link, under Personal Data add GitHub and LinkedIn URLs). These links are essential for credibility.
- HYPERLINKS: Format every link as [Display Text](https://actual.url). Example: [GitHub](https://github.com/username) or [LinkedIn](https://linkedin.com/in/username). Do NOT write raw URLs.
- Use PLAIN TEXT only. NO markdown formatting (no asterisks, no dashes --- or ***, no bullet symbols, no hashtags, no tables).
- Separate sections with blank lines. Use simple sentences and line breaks for structure.
- Do NOT include any future dates or ongoing projects without end dates

$originalPrompt''';
  }

  Future<String> askUniversityChat({
    required UniversityEntity university,
    required String message,
    required List<Map<String, String>> history,
    Map<String, dynamic>? userProfile,
    String languageCode = 'en',
  }) async {
    final uniMap = {
      'name': university.name,
      'location': university.location,
      'rankings': university.rankings,
      'matchPercentage': university.matchPercentage,
      'websiteUrl': university.websiteUrl,
      'description': university.description,
      'programs': university.programs.map((p) => {
        'programName': p.programName,
        'major': p.major,
        'degreeType': p.degreeType,
        'requiredGpa': p.requiredGpa,
        'instructionLanguage': p.instructionLanguage,
        'requiresIelts': p.requiresIelts,
        'minIeltsScore': p.minIeltsScore,
        'acceptsMoi': p.acceptsMoi,
        'deadline': p.deadline,
        'intakeType': p.intakeType,
        'tuitionFeePerYear': p.tuitionFeePerYear,
        'applicationFee': p.applicationFee,
        'matchScore': p.matchScore,
        'isRecommended': p.isRecommended,
      }).toList(),
    };

    final system = AiPrompts.universityChatSystemPrompt(uniMap, userProfile: userProfile);
    final lang = languageCode == 'ar'
        ? '\nIMPORTANT: The user is speaking Arabic. Respond in Arabic. Use formal, respectful Arabic suitable for academic guidance.'
        : '';

    final buffer = StringBuffer();
    buffer.writeln(system);
    buffer.writeln(lang);
    buffer.writeln('\nConversation:');
    for (final msg in history) {
      buffer.writeln('${msg['role']}: ${msg['text']}');
    }
    buffer.writeln('user: $message');
    buffer.writeln('\nAssistant:');

    return _callGemini(buffer.toString(), temperature: 0.3);
  }

  Future<String> generateSop({
    required String programName,
    required String universityName,
    required String degreeType,
    required String major,
    required String studentName,
    required String studentBackground,
    required String programHighlights,
    String languageCode = 'en',
    Uint8List? transcriptPdf,
    Uint8List? bachelorCertPdf,
    Uint8List? existingCvPdf,
  }) async {
    String prompt = AiPrompts.sopGeneration(
      programName: programName,
      universityName: universityName,
      degreeType: degreeType,
      major: major,
      studentName: studentName,
      studentBackground: studentBackground,
      programHighlights: programHighlights,
      languageCode: languageCode,
    );

    final files = <Map<String, dynamic>>[];
    bool hasDocs = false;
    if (transcriptPdf != null) {
      if (!hasDocs) { prompt = _prependDocExtraction(prompt, 'Motivation Letter / SOP'); hasDocs = true; }
      files.add({
        'bytes': transcriptPdf, 'mimeType': 'application/pdf', 'filename': 'transcript.pdf'
      });
    }
    if (bachelorCertPdf != null) {
      if (!hasDocs) { prompt = _prependDocExtraction(prompt, 'Motivation Letter / SOP'); hasDocs = true; }
      files.add({
        'bytes': bachelorCertPdf, 'mimeType': 'application/pdf', 'filename': 'bachelor_cert.pdf'
      });
    }
    if (existingCvPdf != null) {
      if (!hasDocs) { prompt = _prependDocExtraction(prompt, 'Motivation Letter / SOP'); hasDocs = true; }
      files.add({
        'bytes': existingCvPdf, 'mimeType': 'application/pdf', 'filename': 'existing_cv.pdf'
      });
    }

    if (files.isNotEmpty) {
      return await _callGeminiWithMultiplePdfs(prompt, files);
    }
    return await _callGemini(prompt);
  }

  /// Returns true if the AI review list contains actual document feedback
  /// (not empty or "could not see file" style errors).
  static bool hasValidFeedback(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return false;
    final firstIssue =
        (reviews.first['issue']?.toString() ?? '').toLowerCase();
    final cantSee = [
      'cannot see',
      "couldn't see",
      'could not see',
      'no document',
      'no file',
      'no attachment',
      'no pdf',
      'unable to read',
      'cannot read',
      'could not read',
      'do not have access',
      'not provided',
      'not attached',
      'file not found',
    ];
    if (cantSee.any((p) => firstIssue.contains(p))) return false;
    if (reviews.every((r) => (r['suggestion']?.toString() ?? '').isEmpty)) {
      return false;
    }
    return true;
  }

  List<Map<String, dynamic>> _parseJsonResponse(String text) {
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) {
        throw FormatException(
            'No valid JSON array brackets. start=$start end=$end len=${text.length}');
      }
      final cleaned = text.substring(start, end + 1).trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      throw FormatException('JSON parse error: $e');
    }
  }
}
