import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/storage/local_storage_service.dart';
import 'onboarding_states.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingDataState());

  final _supabase = Supabase.instance.client;

  OnboardingDataState get _state => state as OnboardingDataState;

  void changeStep(int step) => emit(_state.copyWith(currentStep: step));

  void updateIntake(String intake) =>
      emit(_state.copyWith(targetIntake: intake));

  void updateStudyLevel(String level) =>
      emit(_state.copyWith(
        studyLevel: level,
        fieldOfInterest: '',
        languagePreference: 'English',
        testType: '',
        hasIELTS: false,
        ieltsScore: 0.0,
        token: '',
        moiConfirmed: false,
        hasMoi: false,
        noneOfTheAbove: false,
        hasGermanCert: false,
        germanCertType: '',
        germanCertLevel: '',
        gpa: 0.0,
        gpaScale: '4.0',
        academicAverage: null,
        highSchoolScore: null,
        hasStudiedUniversity: false,
        tuitionBudget: '',
        studentGoals: const [],
      ));

  void updateField(String field) =>
      emit(_state.copyWith(fieldOfInterest: field));

  // 🎯 تحديث لغة الدراسة المفضلة
  void updateLanguage(String lang) =>
      emit(_state.copyWith(languagePreference: lang));

  void updateTestType(String testType) => emit(
    _state.copyWith(
      testType: testType,
      token: '', // clear token when test type changes
      hasIELTS: testType == 'ielts',
      hasGermanCert: testType == 'german',
      hasMoi: testType == 'moi',
      noneOfTheAbove: testType == 'none',
      ieltsScore: testType == 'ielts' ? 6.0 : 0.0,
    ),
  );

  void updateIeltsStatus(bool hasIelts) => emit(
    _state.copyWith(hasIELTS: hasIelts, ieltsScore: hasIelts ? 6.0 : 0.0),
  );

  void updateIeltsScore(double score) =>
      emit(_state.copyWith(ieltsScore: score));

  void updateMoiConfirmed(bool confirmed) =>
      emit(_state.copyWith(moiConfirmed: confirmed));

  void updateToken(String token) =>
      emit(_state.copyWith(token: token));

  void updateNoneOfTheAbove(bool value) =>
      emit(_state.copyWith(noneOfTheAbove: value));

  void updateGermanCert({required bool hasCert, String type = '', String level = ''}) =>
      emit(_state.copyWith(hasGermanCert: hasCert, germanCertType: type, germanCertLevel: level));

  void updateGpa({double? gpa, String? scale}) => emit(
    _state.copyWith(gpa: gpa ?? _state.gpa, gpaScale: scale ?? _state.gpaScale),
  );

  void updateAcademicAverage(double? avg) =>
    emit(_state.copyWith(academicAverage: avg));

  void updateHighSchoolScore(double? score) =>
    emit(_state.copyWith(highSchoolScore: score));

  void updateHasStudiedUniversity(bool value) =>
    emit(_state.copyWith(hasStudiedUniversity: value));

  void updateBudget(String budget) =>
      emit(_state.copyWith(tuitionBudget: budget));

  void toggleGoal(String goal) {
    final updatedGoals = List<String>.from(_state.studentGoals);
    if (updatedGoals.contains(goal)) {
      updatedGoals.remove(goal);
    } else {
      updatedGoals.add(goal);
    }
    emit(_state.copyWith(studentGoals: updatedGoals));
  }

  Future<void> saveOnboardingData() async {
    final currentState = _state;
    emit(currentState.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase
            .from('profiles')
            .update({
              'target_country': 'Germany',
              'intake': currentState.targetIntake,
              'degree_level': currentState.studyLevel,
              'target_major': currentState.fieldOfInterest,
              'language_preference': currentState.languagePreference,
              'has_ielts': currentState.hasIELTS,
              'ielts_score': currentState.hasIELTS ? currentState.ieltsScore : null,
              'has_toefl': currentState.testType == 'toefl',
              'toefl_score': currentState.testType == 'toefl' ? currentState.ieltsScore : null,
              'has_moi': currentState.testType == 'moi',
              'moi_confirmed': currentState.moiConfirmed,
              'token': currentState.token.isEmpty ? null : currentState.token,
              'has_german_cert': currentState.hasGermanCert,
              'german_cert_type': currentState.germanCertType.isEmpty ? null : currentState.germanCertType,
              'german_cert_level': currentState.germanCertLevel.isEmpty ? null : currentState.germanCertLevel,
              'none_of_the_above': currentState.noneOfTheAbove,
              'gpa': currentState.gpa,
              'academic_average': currentState.hasStudiedUniversity ? currentState.academicAverage : null,
              'high_school_score': currentState.hasStudiedUniversity ? null : currentState.highSchoolScore,
              'budget_range': currentState.tuitionBudget,
              'goals': currentState.studentGoals,
            })
            .eq('id', user.id)
            .timeout(const Duration(seconds: 10));
      }
      // Request notification permission after first-time profile completion
      await LocalStorageService.markOnboardingComplete();
      NotificationService.requestNotificationPermission();
      emit(OnboardingSuccess());
    } catch (e) {
      emit(currentState.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
