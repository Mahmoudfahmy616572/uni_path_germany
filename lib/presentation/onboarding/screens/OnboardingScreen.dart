import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';
import '../widgets/budget_step_widget.dart';
import '../widgets/goals_step_widget.dart';
import '../widgets/gpa_step_widget.dart';
import '../widgets/ielts_score_step_widget.dart';
import '../widgets/ielts_step_widget.dart';
import '../widgets/intake_step_widget.dart';
import '../widgets/language_step_widget.dart'; // 🎯
import '../widgets/major_step_widget.dart';
import '../widgets/study_level_step_widget.dart';
import '../widgets/welcome_step_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final int _totalSteps = 10; // 🎯 زادت لـ 10

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit(),
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingDataState && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is OnboardingSuccess) context.go('/home');
        },
        builder: (context, state) {
          if (state is! OnboardingDataState)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          final cubit = context.read<OnboardingCubit>();
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: state.currentStep > 0 && !state.isLoading
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textDark,
                        size: 20,
                      ),
                      onPressed: () {
                        if (state.currentStep == 7 && state.hasIELTS == false) {
                          // تعديل الـ Skip
                          _pageController.animateToPage(
                            5,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    )
                  : null,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (state.currentStep > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: LinearProgressIndicator(
                        value: state.currentStep / (_totalSteps - 1),
                        backgroundColor: AppColors.inputBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 6.h,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => cubit.changeStep(index),
                      children: [
                        const WelcomeStepWidget(),
                        IntakeStepWidget(cubit: cubit, state: state),
                        StudyLevelStepWidget(cubit: cubit, state: state),
                        MajorStepWidget(cubit: cubit, state: state),
                        LanguageStepWidget(
                          cubit: cubit,
                          state: state,
                        ), // 🎯 الشاشة الجديدة
                        IeltsStepWidget(cubit: cubit, state: state),
                        IeltsScoreStepWidget(cubit: cubit, state: state),
                        GpaStepWidget(cubit: cubit, state: state),
                        BudgetStepWidget(cubit: cubit, state: state),
                        GoalsStepWidget(cubit: cubit, state: state),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(24.r),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () => _handleNextAction(state, cubit),
                        child: state.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _getButtonText(state.currentStep),
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getButtonText(int step) => step == 0
      ? 'Let\'s Get Started →'
      : (step == _totalSteps - 1 ? 'Looks Good! →' : 'Continue');

  void _handleNextAction(OnboardingDataState state, OnboardingCubit cubit) {
    // 🎯 Skip IELTS Score if user doesn't have it
    if (state.currentStep == 5 && state.hasIELTS == false) {
      _pageController.animateToPage(
        7,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    if (state.currentStep == _totalSteps - 1) {
      final collectedData = {
        'targetCountry': 'Germany',
        'intake': state.targetIntake,
        'degreeLevel': state.studyLevel,
        'targetMajor': state.fieldOfInterest,
        'languagePreference': state.languagePreference,
        'hasIelts': state.hasIELTS,
        'ieltsScore': state.hasIELTS ? state.ieltsScore : null,
        'gpa': state.gpa,
        'gpaScale': state.gpaScale,
        'budgetRange': state.tuitionBudget,
        'goals': state.studentGoals,
      };
      context.push('/register', extra: collectedData);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
