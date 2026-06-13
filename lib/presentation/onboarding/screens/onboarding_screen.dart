import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/utils/custom_snack_bar.dart';
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
  final int _totalSteps = 10;

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
          print('🔄 ONBOARDING LISTENER: ${state.runtimeType}');
          if (state is OnboardingDataState && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is OnboardingSuccess) {
            print('🔄 ONBOARDING SUCCESS - going to /home');
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is! OnboardingDataState) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

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
                          _pageController.jumpToPage(5);
                        } else {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 1),
                            curve: Curves.linear,
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
                        onPageChanged: (index) {
                          cubit.changeStep(index);
                        },
                        children: [
                          const WelcomeStepWidget(),
                          IntakeStepWidget(cubit: cubit, state: state),
                          StudyLevelStepWidget(cubit: cubit, state: state),
                          MajorStepWidget(cubit: cubit, state: state),
                          LanguageStepWidget(
                            cubit: cubit,
                            state: state,
                          ),
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
                            : () {
                                print('🔘 BUTTON PRESSED: Step ${state.currentStep}, isLoading: ${state.isLoading}');
                                _handleNextAction(state, cubit);
                              },
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
    // 🎯 Validate current step before proceeding
    final errorMessage = _validateCurrentStep(state);
    if (errorMessage != null) {
      print('🔴 ONBOARDING VALIDATION FAILED: $errorMessage');
      print('🔴 Current step: ${state.currentStep}, Goals: ${state.studentGoals}');
      CustomSnackBar.show(context, message: errorMessage, isError: true);
      return;
    }

    print('✅ ONBOARDING VALIDATION PASSED: Step ${state.currentStep}');

    // 🎯 Skip IELTS Score if user doesn't have it
    if (state.currentStep == 5 && state.hasIELTS == false) {
      _pageController.jumpToPage(7);
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
      print('🚀 Navigating to /register with data: $collectedData');
      context.push('/register', extra: collectedData);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    }
  }

  String? _validateCurrentStep(OnboardingDataState state) {
    switch (state.currentStep) {
      case 1: // Intake
        if (state.targetIntake.isEmpty) return 'Please select when you want to start studying';
        break;
      case 2: // Study Level
        if (state.studyLevel.isEmpty) return 'Please select your study level';
        break;
      case 3: // Major
        if (state.fieldOfInterest.isEmpty) return 'Please select your field of interest';
        break;
      case 4: // Language
        if (state.languagePreference.isEmpty) return 'Please select your language preference';
        break;
      case 5: // IELTS
        if (!state.hasIELTS && state.ieltsScore == 0.0) {
          // This step is just yes/no, validation happens in score step
        }
        break;
      case 6: // IELTS Score
        if (state.hasIELTS && state.ieltsScore <= 0) return 'Please enter your IELTS score';
        break;
      case 7: // GPA
        if (state.gpa <= 0) return 'Please enter your GPA';
        if (state.gpaScale.isEmpty) return 'Please select your GPA scale';
        break;
      case 8: // Budget
        if (state.tuitionBudget.isEmpty) return 'Please select your budget range';
        break;
      case 9: // Goals
        if (state.studentGoals.isEmpty) return 'Please select at least one goal';
        break;
    }
    return null;
  }
}
