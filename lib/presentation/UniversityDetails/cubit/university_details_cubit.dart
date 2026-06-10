// ====================
// FILE: lib/presentation/UniversityDetails/cubit/university_details_cubit.dart
// ====================
//
// التغيير الوحيد عن الأصلي:
//  ✅ في checkInitialSaveStatus — بنحفظ الـ profile في state كـ studentProfile
//  ✅ باقي كل حاجة نفس الأصلي بالظبط:
//     - matchPercentage: int مش double
//     - مفيش allPrograms في الـ state (مش موجودة في الأصلي)
//     - errorMessage اختياري في الـ constructor
//     - loadingProgramIds موجودة في toggleSaveProgram
//     - isFromAction موجودة في الـ emits

import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/program_entity.dart';
import '../../../domain/entities/university_entity.dart';
import '../../../domain/repositories/applications_repository.dart';
import 'university_details_state.dart';

class UniversityDetailsCubit extends Cubit<UniversityDetailsState> {
  final ApplicationsRepository repository;
  List<ProgramEntity> _fullProgramsList = [];

  UniversityDetailsCubit(this.repository) : super(UniversityDetailsInitial());

  void initializeUniversityData({
    required int percentage,
    required List<ProgramEntity> programs,
    required UniversityEntity university,
  }) {
    if (isClosed) return;
    _fullProgramsList = programs;
    emit(
      UniversitySaveStatus(
        isSaved: false,
        // ✅ int مش double
        matchPercentage: percentage,
        displayedPrograms: programs,
        currentUniversity: university,
        fileUploadProgress: const {},
      ),
    );
    checkInitialSaveStatus(university.id);
  }

  void toggleProgramFilter(bool showOnlyRecommended) {
    if (isClosed) return;
    final status = _getCurrentStatus();
    final List<ProgramEntity> filteredList = showOnlyRecommended
        ? _fullProgramsList.where((p) => p.matchScore >= 60).toList()
        : _fullProgramsList;
    emit(
      status.copyWith(
        showOnlyRecommended: showOnlyRecommended,
        displayedPrograms: filteredList,
      ),
    );
  }

  Future<void> toggleSaveProgram({
    required String universityId,
    required String programId,
    required bool currentStatus,
  }) async {
    final status = _getCurrentStatus();
    // ✅ loadingProgramIds موجودة — نفس الأصلي
    final loadingIds = Set<String>.from(status.loadingProgramIds)
      ..add(programId);
    if (!isClosed) {
      emit(status.copyWith(loadingProgramIds: loadingIds, isLoading: true));
    }
    try {
      if (currentStatus) {
        await repository.removeSavedProgram(
          universityId: universityId,
          programId: programId,
        );
      } else {
        await repository.saveProgram(
          universityId: universityId,
          programId: programId,
        );
      }
      final savedIds = Set<String>.from(status.savedProgramIds);
      currentStatus ? savedIds.remove(programId) : savedIds.add(programId);
      if (!isClosed) {
        emit(
          status.copyWith(
            savedProgramIds: savedIds,
            isSaved: savedIds.isNotEmpty,
            loadingProgramIds: Set<String>.from(loadingIds)..remove(programId),
            isLoading: false,
            // ✅ isFromAction موجودة — نفس الأصلي
            isFromAction: true,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          status.copyWith(
            loadingProgramIds: Set<String>.from(loadingIds)..remove(programId),
            isLoading: false,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> updateNotes({
    required String universityId,
    String? programId,
    required String newNotes,
  }) async {
    try {
      await repository.updateApplicationNotes(
        universityId: universityId,
        programId: programId,
        newNotes: newNotes,
      );
      final status = _getCurrentStatus();
      if (status.currentUniversity != null && !isClosed) {
        emit(
          status.copyWith(
            currentUniversity: status.currentUniversity!.copyWith(
              notes: newNotes,
            ),
            isFromAction: true,
          ),
        );
      }
    } catch (e) {}
  }

  Future<void> uploadApplicationFile({
    required String universityId,
    required String columnName,
    required File file,
  }) async {
    final status = _getCurrentStatus();
    if (status.currentUniversity == null || isClosed) return;

    Map<String, double> progressMap = Map<String, double>.from(
      status.fileUploadProgress,
    );
    progressMap[columnName] = 0.1;
    emit(status.copyWith(fileUploadProgress: progressMap));

    try {
      final String url = await repository.uploadDocument(
        universityId: universityId,
        columnName: columnName,
        file: file,
      );

      if (!isClosed) {
        final updatedUni = _updateLocalFiles(
          status.currentUniversity!,
          columnName,
          url,
        );
        progressMap[columnName] = 1.0;
        emit(
          _getCurrentStatus().copyWith(
            fileUploadProgress: Map.from(progressMap),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        progressMap.remove(columnName);
        emit(
          _getCurrentStatus().copyWith(
            fileUploadProgress: progressMap,
            currentUniversity: updatedUni,
            isFromAction: true,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        progressMap.remove(columnName);
        emit(
          _getCurrentStatus().copyWith(
            fileUploadProgress: progressMap,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // checkInitialSaveStatus
  // ─────────────────────────────────────────────────────────
  // ✅ التغيير الوحيد عن الأصلي:
  //    studentProfile: profile — بنحفظ بيانات الطالب في الـ state
  //    عشان ScoreBreakdownWidget يقدر يحسب الـ breakdown بدون DB call
  // ─────────────────────────────────────────────────────────
  Future<void> checkInitialSaveStatus(String universityId) async {
    if (isClosed) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final Map<String, dynamic> profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final status = _getCurrentStatus();
      final savedProgramIds = <String>{};

      for (final program in _fullProgramsList) {
        if (program.id.isEmpty) continue;
        final isSaved = await repository.checkIfSaved(
          universityId,
          programId: program.id,
        );
        if (isSaved) savedProgramIds.add(program.id);
      }

      final updatedUni = status.currentUniversity?.copyWith(
        hasTranscripts: profile['has_transcripts'],
        hasBachelorCert: profile['has_bachelor_cert'],
        hasSop: profile['has_sop'],
        hasCv: profile['has_cv'],
      );

      if (!isClosed) {
        emit(
          status.copyWith(
            currentUniversity: updatedUni,
            savedProgramIds: savedProgramIds,
            isSaved: savedProgramIds.isNotEmpty,
            studentProfile: profile, // ✅ التغيير الوحيد
          ),
        );
      }
    } catch (e) {}
  }

  // ── Helpers ───────────────────────────────────────────────

  UniversitySaveStatus _getCurrentStatus() {
    return state is UniversitySaveStatus
        ? state as UniversitySaveStatus
        // ✅ const constructor — مفيش allPrograms هنا
        : const UniversitySaveStatus(isSaved: false);
  }

  UniversityEntity _updateLocalFiles(
    UniversityEntity uni,
    String col,
    String val,
  ) {
    return uni.copyWith(
      hasTranscripts: col == 'has_transcripts' ? val : uni.hasTranscripts,
      hasBachelorCert: col == 'has_bachelor_cert' ? val : uni.hasBachelorCert,
      hasSop: col == 'has_sop' ? val : uni.hasSop,
      hasCv: col == 'has_cv' ? val : uni.hasCv,
    );
  }
}
