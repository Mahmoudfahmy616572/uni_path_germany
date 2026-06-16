import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

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
    if (_useServer) {
      final response = await _dio.post('$_serverUrl/api/ai/chat',
          data: {
            'prompt': prompt,
            'temperature': temperature,
            'maxOutputTokens': maxOutputTokens,
          });
      return response.data['text'] as String? ?? '';
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
  }

  Future<String> _callGeminiWithPdf(
      String prompt, Uint8List pdfBytes, String mimeType) async {
    if (_useServer) {
      final formData = FormData.fromMap({
        'prompt': prompt,
        'file': MultipartFile.fromBytes(pdfBytes,
            filename: 'document.pdf',
            contentType: DioMediaType.parse(mimeType)),
      });
      final response = await _dio.post('$_serverUrl/api/ai/chat-with-pdf',
          data: formData);
      return response.data['text'] as String? ?? '';
    }

    if (_apiKey == null || _apiKey.isEmpty) {
      throw Exception(
          'No GEMINI_API_KEY or SERVER_URL set. Configure one in .env');
    }

    final base64Data = base64Encode(pdfBytes);
    final response = await _dio.post(
      '$_baseUrl:generateContent?key=$_apiKey',
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Data,
                }
              }
            ]
          }
        ],
      },
    );
    return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '';
  }

  Future<List<Map<String, dynamic>>> getImprovementSuggestions({
    required Map<String, dynamic> studentProfile,
    required Map<String, dynamic> programDetails,
    required Map<String, dynamic> breakdown,
  }) async {
    final prompt = AiPrompts.improvementSuggestions(
      studentProfile: studentProfile,
      programDetails: programDetails,
      breakdown: breakdown,
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
    required String programName,
    required String docType,
    required String documentContent,
  }) async {
    final prompt = AiPrompts.documentReview(
      programName: programName,
      docType: docType,
      documentContent: documentContent,
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
  }) async {
    final prompt = AiPrompts.documentSuggestions(
      studentProfile: studentProfile,
      programDetails: programDetails,
      uploadStatus: uploadStatus,
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
    required String programName,
    required String docType,
    required String title,
    required Uint8List pdfBytes,
    String mimeType = 'application/pdf',
  }) async {
    final prompt =
        'You are a German university admissions officer. Review the attached $title document for the "$programName" program. Give 3-5 specific, actionable improvement suggestions. Return ONLY a JSON array with this exact structure, no markdown, no code fences: [{"issue":"string","severity":"high|medium|low","suggestion":"string"}]';

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
  }) async {
    final prompt = AiPrompts.documentGeneration(
      programName: programName,
      universityName: universityName,
      degreeType: degreeType,
      major: major,
      studentName: studentName,
      studentBackground: studentBackground,
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
  }) async {
    final prompt = AiPrompts.cvGeneration(
      programName: programName,
      universityName: universityName,
      major: major,
      studentName: studentName,
      studentBackground: studentBackground,
      targetDegree: targetDegree,
    );
    return await _callGemini(prompt);
  }

  Future<String> generateSop({
    required String programName,
    required String universityName,
    required String degreeType,
    required String major,
    required String studentName,
    required String studentBackground,
    required String programHighlights,
  }) async {
    final prompt = AiPrompts.sopGeneration(
      programName: programName,
      universityName: universityName,
      degreeType: degreeType,
      major: major,
      studentName: studentName,
      studentBackground: studentBackground,
      programHighlights: programHighlights,
    );
    return await _callGemini(prompt);
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
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw FormatException('JSON parse error: $e');
    }
  }
}
