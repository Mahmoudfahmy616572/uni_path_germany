// ====================
// FILE: lib/presentation/UniversityDetails/cubit/university_details_state.dart
// ====================
//
// التغيير الوحيد عن الأصلي:
//  ✅ أضفنا studentProfile فقط — كل حاجة تانية نفس الأصلي بالظبط

import 'package:equatable/equatable.dart';

import '../../../domain/entities/program_entity.dart';
import '../../../domain/entities/university_entity.dart';

abstract class UniversityDetailsState extends Equatable {
  const UniversityDetailsState();
  @override
  List<Object?> get props => [];
}

class UniversityDetailsInitial extends UniversityDetailsState {}

class UniversitySaveStatus extends UniversityDetailsState {
  final bool isSaved;
  final bool isLoading;
  final String? errorMessage;
  final bool isFromAction;
  // ✅ int مش double — نفس الأصلي
  final int matchPercentage;
  final bool showOnlyRecommended;
  final List<ProgramEntity> displayedPrograms;
  final UniversityEntity? currentUniversity;

  final Set<String> savedProgramIds;
  final Set<String> loadingProgramIds;
  final Map<String, double> fileUploadProgress;

  // ✅ الإضافة الوحيدة
  final Map<String, dynamic>? studentProfile;

  const UniversitySaveStatus({
    required this.isSaved,
    this.isLoading = false,
    // ✅ errorMessage اختياري مش required — نفس الأصلي
    this.errorMessage,
    this.isFromAction = false,
    // ✅ matchPercentage int مع default 0 — نفس الأصلي
    this.matchPercentage = 0,
    this.showOnlyRecommended = false,
    this.displayedPrograms = const [],
    this.savedProgramIds = const {},
    this.loadingProgramIds = const {},
    this.fileUploadProgress = const {},
    this.currentUniversity,
    this.studentProfile,
  });

  @override
  List<Object?> get props => [
    isSaved,
    isLoading,
    errorMessage,
    isFromAction,
    matchPercentage,
    showOnlyRecommended,
    displayedPrograms,
    savedProgramIds,
    loadingProgramIds,
    fileUploadProgress,
    currentUniversity,
    studentProfile,
  ];

  UniversitySaveStatus copyWith({
    bool? isSaved,
    bool? isLoading,
    String? errorMessage,
    bool? isFromAction,
    int? matchPercentage,
    bool? showOnlyRecommended,
    List<ProgramEntity>? displayedPrograms,
    Set<String>? savedProgramIds,
    Set<String>? loadingProgramIds,
    Map<String, double>? fileUploadProgress,
    UniversityEntity? currentUniversity,
    Map<String, dynamic>? studentProfile,
  }) {
    return UniversitySaveStatus(
      isSaved: isSaved ?? this.isSaved,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isFromAction: isFromAction ?? this.isFromAction,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      showOnlyRecommended: showOnlyRecommended ?? this.showOnlyRecommended,
      displayedPrograms: displayedPrograms ?? this.displayedPrograms,
      savedProgramIds: savedProgramIds ?? this.savedProgramIds,
      loadingProgramIds: loadingProgramIds ?? this.loadingProgramIds,
      fileUploadProgress: fileUploadProgress ?? this.fileUploadProgress,
      currentUniversity: currentUniversity ?? this.currentUniversity,
      studentProfile: studentProfile ?? this.studentProfile,
    );
  }
}
