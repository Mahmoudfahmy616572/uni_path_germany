import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

import '../../core/utils/logger.dart';

import '../../core/utils/match_score_calculator.dart';

abstract class ApplicationsRemoteDataSource {
  Future<void> saveProgram({
    required String universityId,
    required String programId,
  });
  Future<List<Map<String, dynamic>>> getMyApplicationsWithScores();
  Future<void> removeSavedProgram({
    required String universityId,
    required String programId,
  });
  Future<bool> checkIfSaved(String universityId, {String? programId});
  Future<String> uploadDocument({
    required String userId,
    required String universityId,
    required String columnName,
    required File file,
    void Function(double progress)? onProgress,
  });
  Future<void> updateNotes({
    required String userId,
    required String universityId,
    String? programId,
    required String newNotes,
  });
  Future<void> updateDocumentStatus({
    required String userId,
    required String columnName,
    required dynamic newValue,
  });
  Future<void> updateApplicationStatus({
    required String universityId,
    required String programId,
    required String newStatus,
  });
  Future<Map<String, dynamic>?> getApplicationDetails({
    required String universityId,
    required String programId,
  });
  Future<void> updatePortalStatus({
    required String userId,
    required String universityId,
    required String programId,
    required String portalStatus,
    String? paymentStatus,
    String? portalUrl,
    String? submittedAt,
    bool? autoTrack,
  });
}

class ApplicationsRemoteDataSourceImpl implements ApplicationsRemoteDataSource {
  final SupabaseClient client;
  ApplicationsRemoteDataSourceImpl(this.client);

  @override
  Future<void> saveProgram({
    required String universityId,
    required String programId,
  }) async {
    final user = client.auth.currentUser;
    await client.from('my_applications').insert({
      'user_id': user!.id,
      'university_id': universityId,
      'program_id': programId,
      'status': 'saved',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getMyApplicationsWithScores() async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    final response = await client
        .from('my_applications')
        .select('*, universities(*, university_programs(*))')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final rawApps = List<Map<String, dynamic>>.from(response as List);
    final userData = (await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle()) ?? <String, dynamic>{};

    final hydratedApps = <Map<String, dynamic>>[];

    for (var item in rawApps) {
      final uniData = Map<String, dynamic>.from(item['universities'] as Map);
      final String savedId = item['program_id'].toString();
      final programs = uniData['university_programs'] as List? ?? [];
      final selectedProg = programs
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .firstWhere(
        (p) => p['id'].toString() == savedId,
        orElse: () => <String, dynamic>{},
      );

      if (selectedProg.isEmpty) {
        continue;
      }

      uniData['university_programs'] = [selectedProg];
      item['universities'] = uniData;

      item['calculated_score'] = MatchScoreCalculator.calculate(
        studentProfile: userData,
        programRequiredGpa:
            (selectedProg['required_gpa'] as num?)?.toDouble() ?? 0.0,
        programRequiresIelts: selectedProg['requires_ielts'] ?? false,
        programMinIelts:
            (selectedProg['min_ielts_score'] as num?)?.toDouble() ?? 0.0,
        programAcceptsMoi: selectedProg['accepts_moi'] ?? false,
        programMajor: selectedProg['major']?.toString() ?? '',
        programName: selectedProg['program_name']?.toString() ?? '',
        programLanguage:
            selectedProg['instruction_language']?.toString() ?? 'English',
        programDegree: selectedProg['degree_type']?.toString() ?? '',
      );
      item['user_profile_data'] = userData;
      hydratedApps.add(item);
    }
    return hydratedApps;
  }

  @override
  Future<void> removeSavedProgram({
    required String universityId,
    required String programId,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    log.i("Deleting: User:$universityId, Prog:$programId");

    await client
        .from('my_applications')
        .delete()
        .eq('user_id', user.id)
        .eq('university_id', universityId)
        .eq('program_id', programId);

    log.i("DB Delete completed");
  }

  @override
  Future<bool> checkIfSaved(String universityId, {String? programId}) async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    var query = client
        .from('my_applications')
        .select('id')
        .eq('user_id', user.id)
        .eq('university_id', universityId);
    if (programId != null) query = query.eq('program_id', programId);
    final response = await query.maybeSingle();
    return response != null;
  }

  @override
  Future<String> uploadDocument({
    required String userId,
    required String universityId,
    required String columnName,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final user = client.auth.currentUser;
    final userLabel = _getUserLabel(user);
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$userLabel/global/$columnName.$ext';

    // Compress PDF via server before upload (only for large files)
    File uploadFile = file;
    if (ext == 'pdf' && file.lengthSync() > 512 * 1024) {
      uploadFile = await _compressPdfIfAvailable(file);
    }

    // Delete old file before uploading new one
    await _deleteExistingFile(path);

    const maxRetries = 3;
    final accessToken = client.auth.currentSession?.accessToken;
    if (accessToken == null) throw Exception('No auth session');
    final storageBaseUrl = client.storage.url;
    final uploadUrl = '$storageBaseUrl/object/documents/$path';

    final uploadDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'apiKey': client.auth.currentSession?.accessToken ?? '',
      },
    ));

    final bytes = await uploadFile.readAsBytes();

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await uploadDio.post(
          uploadUrl,
          data: bytes,
          options: Options(
            headers: {
              'Content-Type': ext == 'pdf' ? 'application/pdf' : 'application/octet-stream',
              'x-upsert': 'true',
            },
          ),
          onSendProgress: (sent, total) {
            if (onProgress != null && total > 0) {
              onProgress(sent / total);
            }
          },
        );
        break;
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    final url = client.storage.from('documents').getPublicUrl(path);
    await client.from('profiles').update({columnName: url}).eq('id', userId);
    return url;
  }

  /// Send the PDF to the server proxy for Ghostscript compression.
  /// Falls back to original file if server is not available.
  Future<File> _compressPdfIfAvailable(File file) async {
    final serverUrl = const String.fromEnvironment('SERVER_URL', defaultValue: '');
    if (serverUrl.isEmpty) return file;

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 120),
      ));
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: 'document.pdf'),
      });
      final response = await dio.post('$serverUrl/api/compress-pdf',
          data: formData,
          options: Options(responseType: ResponseType.bytes));

      if (response.statusCode == 200 &&
          response.data is List<int> &&
          (response.data as List<int>).isNotEmpty) {
        final compressed = response.data as List<int>;
        // Only use if actually smaller
        if (compressed.length < file.lengthSync()) {
          final temp = File('${file.path}.compressed.pdf');
          await temp.writeAsBytes(compressed);
          return temp;
        }
      }
    } catch (_) {
      // Server not reachable — use original
    }
    return file;
  }

  String _getUserLabel(User? user) {
    if (user == null) return 'unknown';
    final displayName = user.userMetadata?['full_name']?.toString() ??
        user.userMetadata?['name']?.toString() ?? '';
    if (displayName.isNotEmpty) return _sanitizeLabel(displayName);
    if (user.email != null && user.email!.contains('@')) {
      return _sanitizeLabel(user.email!.split('@').first);
    }
    return user.id;
  }

  String _sanitizeLabel(String label) {
    return label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_\-.]'), '').trim();
  }

  Future<void> _deleteExistingFile(String path) async {
    try {
      await client.storage.from('documents').remove([path]);
    } catch (_) {
      // File doesn't exist or can't be deleted — proceed with upload
    }
  }

  @override
  Future<void> updateNotes({
    required String userId,
    required String universityId,
    String? programId,
    required String newNotes,
  }) async {
    var query = client
        .from('my_applications')
        .update({'notes': newNotes})
        .eq('user_id', userId)
        .eq('university_id', universityId);
    if (programId != null) query = query.eq('program_id', programId);
    await query;
  }

  @override
  Future<void> updateDocumentStatus({
    required String userId,
    required String columnName,
    required dynamic newValue,
  }) async {
    await client
        .from('profiles')
        .update({columnName: newValue})
        .eq('id', userId);
  }

  @override
  Future<void> updateApplicationStatus({
    required String universityId,
    required String programId,
    required String newStatus,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    await client
        .from('my_applications')
        .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
        .eq('user_id', user.id)
        .eq('university_id', universityId)
        .eq('program_id', programId);
  }

  @override
  Future<Map<String, dynamic>?> getApplicationDetails({
    required String universityId,
    required String programId,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('my_applications')
        .select('*, universities(name), university_programs(program_name)')
        .eq('user_id', user.id)
        .eq('university_id', universityId)
        .eq('program_id', programId)
        .maybeSingle();

    return response;
  }

  @override
  Future<void> updatePortalStatus({
    required String userId,
    required String universityId,
    required String programId,
    required String portalStatus,
    String? paymentStatus,
    String? portalUrl,
    String? submittedAt,
    bool? autoTrack,
  }) async {
    final updateMap = <String, dynamic>{
      'portal_status': portalStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (paymentStatus != null) updateMap['payment_status'] = paymentStatus;
    if (portalUrl != null) updateMap['portal_url'] = portalUrl;
    if (submittedAt != null) updateMap['submitted_at'] = submittedAt;
    if (autoTrack != null) updateMap['auto_track'] = autoTrack;

    await client
        .from('my_applications')
        .update(updateMap)
        .eq('user_id', userId)
        .eq('university_id', universityId)
        .eq('program_id', programId);
  }
}
