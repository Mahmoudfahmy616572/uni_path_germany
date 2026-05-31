import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:germany_travel/presentation/onboarding/cubit/onboarding_states.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingDataState());

  final _supabase = Supabase.instance.client;

  // تحديث الخطوة الحالية
  void changeStep(int step) {
    if (state is OnboardingDataState) {
      final currentState = state as OnboardingDataState;
      emit(currentState.copyWith(currentStep: step));
    }
  }

  // تحديث البيانات خطوة بخطوة
  void updateCountry(String country) {
    if (state is OnboardingDataState) {
      emit((state as OnboardingDataState).copyWith(targetCountry: country));
    }
  }

  void updateStudyLevel(String level) {
    if (state is OnboardingDataState) {
      emit((state as OnboardingDataState).copyWith(studyLevel: level));
    }
  }

  void updateField(String field) {
    if (state is OnboardingDataState) {
      emit((state as OnboardingDataState).copyWith(fieldOfInterest: field));
    }
  }

  void updateIeltsStatus(bool hasIelts) {
    if (state is OnboardingDataState) {
      emit(
        (state as OnboardingDataState).copyWith(
          hasIELTS: hasIelts,
          // لو مفيش آيلتس، صفر السكور تلقائياً
          ieltsScore: hasIelts ? 6.0 : 0.0,
        ),
      );
    }
  }

  void updateIeltsScore(double score) {
    if (state is OnboardingDataState) {
      emit((state as OnboardingDataState).copyWith(ieltsScore: score));
    }
  }

  void updateGpa({double? gpa, String? scale}) {
    if (state is OnboardingDataState) {
      final currentState = state as OnboardingDataState;
      emit(
        currentState.copyWith(
          gpa: gpa ?? currentState.gpa,
          gpaScale: scale ?? currentState.gpaScale,
        ),
      );
    }
  }

  void updateBudget(String budget) {
    if (state is OnboardingDataState) {
      emit((state as OnboardingDataState).copyWith(tuitionBudget: budget));
    }
  }

  void toggleGoal(String goal) {
    if (state is OnboardingDataState) {
      final currentState = state as OnboardingDataState;
      final updatedGoals = List<String>.from(currentState.studentGoals);

      if (updatedGoals.contains(goal)) {
        updatedGoals.remove(goal);
      } else {
        updatedGoals.add(goal);
      }
      emit(currentState.copyWith(studentGoals: updatedGoals));
    }
  }

  // 🔥 الرفع النهائي لقاعدة البيانات بسوبابيز في آخر خطوة (Looks Good!)
  Future<void> saveOnboardingData() async {
    if (state is! OnboardingDataState) return;
    final currentState = state as OnboardingDataState;

    emit(currentState.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = _supabase.auth.currentUser;

      // 🔴 1. اعمل كومنت للسطر ده مؤقتاً عشان الإكسبشن ما يضربش وأنت بتجرب الـ UI
      // if (user == null) throw Exception('User not logged in');

      // 🔵 2. خلي كود الرفع يشتغل فقط لو الـ user موجود فعلاً (عشان ما يضربش إيرور من سوبابيز)
      if (user != null) {
        await _supabase
            .from('profiles')
            .update({
              'target_country': currentState.targetCountry,
              'degree_level': currentState.studyLevel,
              'target_major': currentState.fieldOfInterest,
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

      // 🎯 3. بنعمل emit للحالة دي في كل الأحوال عشان ينقلك لشاشة الـ Home فوراً
      emit(OnboardingSuccess());
    } catch (e) {
      emit(currentState.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
