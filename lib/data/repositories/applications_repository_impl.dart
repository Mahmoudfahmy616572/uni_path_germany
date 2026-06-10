import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/university_entity.dart';
import '../../domain/repositories/applications_repository.dart';
import '../models/university_model.dart';
import '../sources/applications_remote_data_source.dart';

class ApplicationsRepositoryImpl implements ApplicationsRepository {
  final ApplicationsRemoteDataSource remoteDataSource;
  ApplicationsRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> saveProgram({
    required String universityId,
    required String programId,
  }) async {
    await remoteDataSource.saveProgram(
      universityId: universityId,
      programId: programId,
    );
  }

  @override
  Future<List<UniversityEntity>> getMyApplications() async {
    final rawApps = await remoteDataSource.getMyApplicationsWithScores();

    return rawApps.map((item) {
      final uniData = Map<String, dynamic>.from(item['universities'] as Map);
      final userData = item['user_profile_data'] as Map<String, dynamic>;

      // ✅ إصلاح الـ Delete Bug:
      // كل صف في my_applications له program_id محدد (البرنامج المحفوظ فعلاً).
      // لكن uniData['university_programs'] بيجيب كل برامج الجامعة مش البرنامج المحفوظ بس.
      // النتيجة: app.programs.first.id بيكون أول برنامج في الجامعة مش البرنامج المحفوظ،
      // وبالتالي الـ delete query بتبقى غلط وما بتلاقيش الصف.
      //
      // الحل: نفلتر university_programs عشان يفضل فيها البرنامج المحفوظ بس.
      final String savedProgramId = item['program_id'].toString();
      if (uniData['university_programs'] != null) {
        final allPrograms = List<Map<String, dynamic>>.from(
          (uniData['university_programs'] as List).map(
            (p) => Map<String, dynamic>.from(p as Map),
          ),
        );
        final savedProg = allPrograms.firstWhere(
          (p) => p['id'].toString() == savedProgramId,
          orElse: () => allPrograms.first, // fallback لو ما لقاش (نادر جداً)
        );
        uniData['university_programs'] = [savedProg];
      }

      // الموديل يقوم فقط بالتحويل (Mapping)
      return UniversityModel.fromJson(
        uniData,
        calculatedScore: item['calculated_score'],
        currentStatus: item['status'],
      ).copyWith(
        notes: item['notes'] ?? '',
        hasTranscripts: userData['has_transcripts'],
        hasCv: userData['has_cv'],
        hasSop: userData['has_sop'],
        hasBachelorCert: userData['has_bachelor_cert'],
      );
    }).toList();
  }

  @override
  Future<bool> checkIfSaved(String universityId, {String? programId}) async {
    return await remoteDataSource.checkIfSaved(
      universityId,
      programId: programId,
    );
  }

  @override
  Future<void> removeSavedProgram({
    required String universityId,
    required String programId,
  }) async {
    await remoteDataSource.removeSavedProgram(
      universityId: universityId,
      programId: programId,
    );
  }

  @override
  Future<String> uploadDocument({
    required String universityId,
    required String columnName,
    required File file,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    return await remoteDataSource.uploadDocument(
      userId: user!.id,
      universityId: universityId,
      columnName: columnName,
      file: file,
    );
  }

  @override
  Future<void> updateApplicationDocument({
    required String universityId,
    String? programId,
    required String columnName,
    required dynamic newValue,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    await remoteDataSource.updateDocumentStatus(
      userId: user!.id,
      columnName: columnName,
      newValue: newValue,
    );
  }

  @override
  Future<void> updateApplicationNotes({
    required String universityId,
    String? programId,
    required String newNotes,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    await remoteDataSource.updateNotes(
      userId: user!.id,
      universityId: universityId,
      programId: programId,
      newNotes: newNotes,
    );
  }

  @override
  Future<void> updateApplicationStatus({
    required String universityId,
    required String programId,
    required String newStatus,
  }) async {
    await remoteDataSource.updateApplicationStatus(
      universityId: universityId,
      programId: programId,
      newStatus: newStatus,
    );
  }

  @override
  Future<Map<String, dynamic>?> getApplicationDetails({
    required String universityId,
    required String programId,
  }) async {
    return await remoteDataSource.getApplicationDetails(
      universityId: universityId,
      programId: programId,
    );
  }
}
