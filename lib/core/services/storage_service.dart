import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const _bucketName = 'university-assets';

  static Future<String?> uploadImage(String path, File file) async {
    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await Supabase.instance.client.storage
            .from(_bucketName)
            .upload(path, file, fileOptions: const FileOptions(upsert: true))
            .timeout(const Duration(seconds: 60));
        return Supabase.instance.client.storage
            .from(_bucketName)
            .getPublicUrl(path);
      } on StorageException catch (e) {
        if (attempt == maxRetries - 1) {
          if (e.message.contains('bucket') || e.message.contains('not found') || e.message.contains('does not exist')) {
            return null;
          }
          if (e.message.contains('policy') || e.statusCode == '401' || e.statusCode == '403') {
            return 'Permission denied. Check RLS policies on storage.objects.';
          }
          return 'Upload error: ${e.message}';
        }
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } catch (e) {
        if (attempt == maxRetries - 1) {
          return 'Unexpected error: $e';
        }
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    return null;
  }
}
