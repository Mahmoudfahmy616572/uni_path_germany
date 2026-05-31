import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/universities_repository.dart';
import 'complete_profile_state.dart';

class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  final UniversitiesRepository universitiesRepository;

  CompleteProfileCubit(this.universitiesRepository)
    : super(CompleteProfileInitial());

  Future<void> submitProfileData({
    required double gpa,
    required double maxGpa,
    required double minGpa,
    required bool hasMoi,
    required bool hasIelts,
    double? ieltsScore,
    required String targetMajor,
    required String targetCountry,
  }) async {
    emit(CompleteProfileLoading());
    try {
      await universitiesRepository.completeStudentProfile(
        gpa: gpa,
        maxGpa: maxGpa,
        minGpa: minGpa,
        hasMoi: hasMoi,
        hasIelts: hasIelts,
        ieltsScore: ieltsScore,
        targetMajor: targetMajor,
        targetCountry: targetCountry,
      );
      emit(CompleteProfileSuccess());
    } catch (e) {
      emit(CompleteProfileError(e.toString()));
    }
  }
}
