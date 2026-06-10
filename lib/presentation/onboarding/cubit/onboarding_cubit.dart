import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'onboarding_states.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingDataState());

  final _supabase = Supabase.instance.client;

  OnboardingDataState get _state => state as OnboardingDataState;

  void changeStep(int step) => emit(_state.copyWith(currentStep: step));

  void updateIntake(String intake) =>
      emit(_state.copyWith(targetIntake: intake));

  void updateStudyLevel(String level) =>
      emit(_state.copyWith(studyLevel: level));

  void updateField(String field) =>
      emit(_state.copyWith(fieldOfInterest: field));

  // 🎯 تحديث لغة الدراسة المفضلة
  void updateLanguage(String lang) =>
      emit(_state.copyWith(languagePreference: lang));

  void updateIeltsStatus(bool hasIelts) => emit(
    _state.copyWith(hasIELTS: hasIelts, ieltsScore: hasIelts ? 6.0 : 0.0),
  );

  void updateIeltsScore(double score) =>
      emit(_state.copyWith(ieltsScore: score));

  void updateGpa({double? gpa, String? scale}) => emit(
    _state.copyWith(gpa: gpa ?? _state.gpa, gpaScale: scale ?? _state.gpaScale),
  );

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
              'language_preference':
                  currentState.languagePreference, // 🎯 حفظ اللغة
              'has_ielts': currentState.hasIELTS,
              'ielts_score': currentState.hasIELTS
                  ? currentState.ieltsScore
                  : null,
              'gpa': currentState.gpa,
              'budget_range': currentState.tuitionBudget,
              'goals': currentState.studentGoals,
            })
            .eq('id', user.id);
      }
      emit(OnboardingSuccess());
    } catch (e) {
      emit(currentState.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
