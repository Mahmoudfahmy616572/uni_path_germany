import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

import 'package:shelf_multipart/form_data.dart';

class CompressHandler {
  Future<Response> compressPdf(Request request) async {
    try {
      Uint8List? pdfBytes;

      await for (final formData in request.multipartFormData) {
        if (formData.name == 'file') {
          final part = formData.part;
          pdfBytes = await part.readBytes();
        }
      }

      if (pdfBytes == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'file is required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Skip compression if file is small (< 512 KB)
      if (pdfBytes.length < 512 * 1024) {
        return Response.ok(
          pdfBytes,
          headers: {
            'content-type': 'application/pdf',
            'content-length': pdfBytes.length.toString(),
          },
        );
      }

      // Try Ghostscript compression via stdin/stdout
      try {
        final proc = await Process.start('gs', [
          '-sDEVICE=pdfwrite',
          '-dCompatibilityLevel=1.4',
          '-dPDFSETTINGS=/ebook',
          '-dNOPAUSE',
          '-dQUIET',
          '-dBATCH',
          '-sOutputFile=-',
          '-',
        ]);
        proc.stdin.add(pdfBytes);
        await proc.stdin.close();
        final chunks = <List<int>>[];
        await for (final chunk in proc.stdout) {
          chunks.add(chunk);
        }
        final exitCode = await proc.exitCode;
        if (exitCode == 0 && chunks.isNotEmpty) {
          final total = chunks.fold<int>(0, (a, b) => a + b.length);
          if (total < pdfBytes.length) {
            final allBytes = <int>[];
            for (final chunk in chunks) {
              allBytes.addAll(chunk);
            }
            return Response.ok(
              allBytes,
              headers: {
                'content-type': 'application/pdf',
                'content-length': allBytes.length.toString(),
              },
            );
          }
        }
      } catch (_) {
        // Ghostscript not installed — return original
      }

      return Response.ok(
        pdfBytes,
        headers: {
          'content-type': 'application/pdf',
          'content-length': pdfBytes.length.toString(),
        },
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
