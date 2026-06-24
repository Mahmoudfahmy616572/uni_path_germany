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

import '../../../core/services/gamification_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/match_score_calculator.dart';
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
        GamificationService.incrementStat('universities_saved');
        ReviewService.registerPositiveAction();
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
    } catch (e) {
      log.e('Error updating notes: $e');
    }
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
    progressMap[columnName] = 0.0;
    emit(status.copyWith(fileUploadProgress: progressMap));

    DateTime lastProgressEmit = DateTime.now();

    try {
      final String url = await repository.uploadDocument(
        universityId: universityId,
        columnName: columnName,
        file: file,
        onProgress: (progress) {
          if (!isClosed) {
            final now = DateTime.now();
            if (now.difference(lastProgressEmit).inMilliseconds < 50) return;
            lastProgressEmit = now;
            final map = Map<String, double>.from(
              _getCurrentStatus().fileUploadProgress,
            );
            map[columnName] = progress;
            emit(_getCurrentStatus().copyWith(fileUploadProgress: map));
          }
        },
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

      Map<String, dynamic> profile = (await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()) ?? <String, dynamic>{};

      // Verify that stored document URLs still point to existing files
      profile = await _verifyDocumentUrls(profile, user);

      // 🎯 تحديث matchScore لكل برنامج بناءً على أحدث بيانات الطالب
      _fullProgramsList = _fullProgramsList.map((p) {
        final int recalculated = MatchScoreCalculator.calculate(
          studentProfile: profile,
          programRequiredGpa: p.requiredGpa,
          programRequiresIelts: p.requiresIelts,
          programMinIelts: p.minIeltsScore,
          programAcceptsMoi: p.acceptsMoi,
          programMajor: p.major,
          programName: p.programName,
          programLanguage: p.instructionLanguage,
          programDegree: p.degreeType,
        );
        return ProgramEntity(
          id: p.id,
          programName: p.programName,
          major: p.major,
          requiredGpa: p.requiredGpa,
          requiresIelts: p.requiresIelts,
          minIeltsScore: p.minIeltsScore,
          acceptsMoi: p.acceptsMoi,
          instructionLanguage: p.instructionLanguage,
          degreeType: p.degreeType,
          deadline: p.deadline,
          applicationFee: p.applicationFee,
          tuitionFeePerYear: p.tuitionFeePerYear,
          curriculum: p.curriculum,
          isRecommended: recalculated >= 60,
          intakeType: p.intakeType,
          matchScore: recalculated,
          programUrl: p.programUrl,
        );
      }).toList();

      final status = _getCurrentStatus();
      final savedProgramIds = await repository.getSavedProgramIds(
        user.id,
        universityId,
      );

      final updatedUni = status.currentUniversity?.copyWith(
        hasTranscripts: profile['has_transcripts'],
        hasBachelorCert: profile['has_bachelor_cert'],
        hasSop: profile['has_sop'],
        hasCv: profile['has_cv'],
        hasLanguageCert: profile['has_language_cert'],
      );

      // 🎯 حساب أعلى match بين البرامج عشان نحدث percentage الجامعة
      final int maxProgramScore = _fullProgramsList.isEmpty
          ? 0
          : _fullProgramsList.map((p) => p.matchScore).reduce(
                (a, b) => a > b ? a : b,
              );

      if (!isClosed) {
        emit(
          status.copyWith(
            matchPercentage: maxProgramScore,
            currentUniversity: updatedUni,
            displayedPrograms: _fullProgramsList,
            savedProgramIds: savedProgramIds,
            isSaved: savedProgramIds.isNotEmpty,
            studentProfile: profile,
          ),
        );
      }
    } catch (e) {
      log.e('Error checking save status: $e');
    }
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
      hasLanguageCert: col == 'has_language_cert' ? val : uni.hasLanguageCert,
    );
  }

  /// Checks stored document URLs against actual files in Supabase Storage.
  /// Clears any URL that points to a deleted file and persists the cleanup.
  Future<Map<String, dynamic>> _verifyDocumentUrls(
      Map<String, dynamic> profile, User user) async {
    const docCols = [
      'has_transcripts',
      'has_bachelor_cert',
      'has_sop',
      'has_cv',
      'has_language_cert',
    ];

    final futures = docCols.map((col) async {
      final url = profile[col]?.toString() ?? '';
      if (!url.startsWith('http')) return null;
      if (await _urlExists(url)) return null;
      return col;
    }).toList();

    final staleCols =
        (await Future.wait(futures)).whereType<String>().toList();

    if (staleCols.isEmpty) return profile;

    final updates = <String, dynamic>{};
    for (final col in staleCols) {
      updates[col] = null;
    }
    await Supabase.instance.client
        .from('profiles')
        .update(updates)
        .eq('id', user.id);

    for (final col in staleCols) {
      profile[col] = null;
    }
    return profile;
  }

  Future<void> updatePortalStatus({
    required String universityId,
    required String programId,
    required String portalStatus,
    String? paymentStatus,
    String? portalUrl,
    String? submittedAt,
    bool? autoTrack,
  }) async {
    try {
      await repository.updatePortalStatus(
        universityId: universityId,
        programId: programId,
        portalStatus: portalStatus,
        paymentStatus: paymentStatus,
        portalUrl: portalUrl,
        submittedAt: submittedAt,
        autoTrack: autoTrack,
      );
    } catch (e) {
      log.e('updateApplicationPortal error: $e');
    }
  }

  Future<bool> _urlExists(String url) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(url);
      final req = await client.headUrl(uri);
      final response = await req.close();
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      log.e('_urlExists error for $url: $e');
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
