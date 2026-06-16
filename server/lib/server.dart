import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'handlers/ai_handler.dart';

Middleware corsHeaders() {
  return (innerHandler) {
    return (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(null, headers: {
          'access-control-allow-origin': '*',
          'access-control-allow-methods': 'POST, GET, OPTIONS',
          'access-control-allow-headers': 'Content-Type',
        });
      }
      final response = await innerHandler(request);
      return response.change(headers: {
        'access-control-allow-origin': '*',
        ...response.headers,
      });
    };
  };
}

Future<void> main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('ERROR: GEMINI_API_KEY environment variable is not set');
    exit(1);
  }

  final aiHandler = AiHandler(apiKey);

  final router = Router()
    ..post('/api/ai/chat', aiHandler.chat)
    ..post('/api/ai/chat-with-pdf', aiHandler.chatWithPdf);

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final server = await io.serve(handler, host, port);
  print('AI Proxy running on http://$host:${server.port}');
}
