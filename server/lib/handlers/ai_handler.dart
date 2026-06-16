import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shelf/shelf.dart';

import 'package:shelf_multipart/form_data.dart';

class AiHandler {
  final String _apiKey;

  AiHandler(this._apiKey);

  GenerativeModel _model({
    double temperature = 0.4,
    int maxOutputTokens = 8192,
  }) =>
      GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        requestOptions: const RequestOptions(apiVersion: 'v1'),
        generationConfig: GenerationConfig(
          temperature: temperature,
          maxOutputTokens: maxOutputTokens,
        ),
      );

  Future<Response> chat(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final prompt = body['prompt'] as String?;
      if (prompt == null || prompt.isEmpty) {
        return Response.badRequest(
            body: jsonEncode({'error': 'prompt is required'}));
      }

      final temperature = (body['temperature'] as num?)?.toDouble() ?? 0.4;
      final maxTokens = (body['maxOutputTokens'] as num?)?.toInt() ?? 8192;

      final model =
          _model(temperature: temperature, maxOutputTokens: maxTokens);
      final response = await model.generateContent([Content.text(prompt)]);

      return Response.ok(
        jsonEncode({'text': response.text ?? ''}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> chatWithPdf(Request request) async {
    try {
      String? prompt;
      Uint8List? pdfBytes;
      String? mimeType;

      await for (final formData in request.multipartFormData) {
        switch (formData.name) {
          case 'prompt':
            prompt = await formData.part.readString();
          case 'file':
            final part = formData.part;
            final ctype = part.headers['content-type'];
            mimeType = ctype ?? 'application/pdf';
            pdfBytes = await part.readBytes();
        }
      }

      if (prompt == null || prompt.isEmpty) {
        return Response.badRequest(
            body: jsonEncode({'error': 'prompt is required'}));
      }
      if (pdfBytes == null) {
        return Response.badRequest(
            body: jsonEncode({'error': 'file is required'}));
      }

      final model = _model();
      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType!, pdfBytes),
      ]);
      final response = await model.generateContent([content]);

      return Response.ok(
        jsonEncode({'text': response.text ?? ''}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
