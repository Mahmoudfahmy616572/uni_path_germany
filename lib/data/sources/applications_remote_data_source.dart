import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

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

    print(
      "🗑️ Attempting to delete from DB: User:${user.id}, Uni:$universityId, Prog:$programId",
    );

    // 🎯 الحذف باستخدام الثلاثة شروط لضمان الدقة واختفاء العنصر
    await client
        .from('my_applications')
        .delete()
        .eq('user_id', user.id)
        .eq('university_id', universityId)
        .eq('program_id', programId);

    print("✅ DB Delete operation completed");
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
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$userId/global/$columnName.$ext';
    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await client.storage
            .from('documents')
            .upload(path, file, fileOptions: const FileOptions(upsert: true))
            .timeout(const Duration(seconds: 60));
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
}
