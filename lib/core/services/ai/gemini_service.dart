import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_prompts.dart';

class GeminiService {
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKey,
          requestOptions: const RequestOptions(apiVersion: 'v1'),
          generationConfig: GenerationConfig(
            temperature: 0.4,
            maxOutputTokens: 8192,
          ),
        );

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

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '[]';
    final result = _parseJsonResponse(text);
    if (result.isEmpty && text != '[]') {
      final preview = text.length > 200 ? '${text.substring(0, 100)}...[${text.length} chars]...${text.substring(text.length - 100)}' : text;
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

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '[]';
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
    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '[]';
    final result = _parseJsonResponse(text);
    if (result.isEmpty && text != '[]') {
      final preview = text.length > 200 ? '${text.substring(0, 100)}...[${text.length} chars]...${text.substring(text.length - 100)}' : text;
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
    final prompt = 'You are a German university admissions officer. Review the attached $title document for the "$programName" program. Give 3-5 specific, actionable improvement suggestions. Return ONLY a JSON array with this exact structure, no markdown, no code fences: [{"issue":"string","severity":"high|medium|low","suggestion":"string"}]';

    final content = Content.multi([
      TextPart(prompt),
      DataPart(mimeType, pdfBytes),
    ]);
    final response = await _model.generateContent([content]);
    final text = response.text ?? '[]';
    final result = _parseJsonResponse(text);
    if (result.isEmpty && text != '[]') {
      throw Exception('PDF review parse failed. Text: ${text.length > 200 ? text.substring(0, 200) : text}');
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

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Generation failed. Please try again.';
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

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Generation failed. Please try again.';
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

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Generation failed. Please try again.';
  }

  List<Map<String, dynamic>> _parseJsonResponse(String text) {
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) {
        throw FormatException('No valid JSON array brackets. start=$start end=$end len=${text.length}');
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
