import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';
import '../widgets/budget_step_widget.dart';
import '../widgets/country_step_widget.dart';
import '../widgets/goals_step_widget.dart';
import '../widgets/gpa_step_widget.dart';
import '../widgets/ielts_score_step_widget.dart';
import '../widgets/ielts_step_widget.dart';
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
  final int _totalSteps = 9; // إجمالي عدد الشاشات من 0 لـ 8

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
          if (state is OnboardingSuccess) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is! OnboardingDataState) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final cubit = context.read<OnboardingCubit>();

          return Scaffold(
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
                        // لو راجعين من الـ GPA وكان عامل Skip للـ IELTS Score، يرجعه لخطوة الـ IELTS الأساسية (خطوة 4)
                        if (state.currentStep == 6 && state.hasIELTS == false) {
                          _pageController.animateToPage(
                            4,
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
              actions: [
                if (state.currentStep == 0)
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                    ),
                  ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // 1️⃣ مؤشر التقدم العلوي (Linear Progress Indicator)
                  if (state.currentStep > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${state.currentStep} of ${_totalSteps - 1}',
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: state.currentStep / (_totalSteps - 1),
                            backgroundColor: AppColors.inputBackground,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                    ),

                  // 2️⃣ الـ PageView الرئيسي المرتب بالملي
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => cubit.changeStep(index),
                      children: [
                        const WelcomeStepWidget(), // خطوة 0
                        CountryStepWidget(cubit: cubit, state: state), // خطوة 1
                        StudyLevelStepWidget(
                          cubit: cubit,
                          state: state,
                        ), // خطوة 2
                        MajorStepWidget(cubit: cubit, state: state), // خطوة 3
                        IeltsStepWidget(cubit: cubit, state: state), // خطوة 4
                        IeltsScoreStepWidget(
                          cubit: cubit,
                          state: state,
                        ), // خطوة 5
                        GpaStepWidget(cubit: cubit, state: state), // خطوة 6
                        BudgetStepWidget(cubit: cubit, state: state), // خطوة 7
                        GoalsStepWidget(cubit: cubit, state: state), // خطوة 8
                      ],
                    ),
                  ),

                  // 3️⃣ أزرار التحكم السفلية الثابتة
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
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
                                style: const TextStyle(
                                  fontSize: 18,
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

  String _getButtonText(int step) {
    if (step == 0) return 'Let\'s Get Started →';
    if (step == _totalSteps - 1) return 'Looks Good! →';
    return 'Continue';
  }

  void _handleNextAction(OnboardingDataState state, OnboardingCubit cubit) {
    // خطوة 1: الدولة
    if (state.currentStep == 1 && state.targetCountry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your preferred country')),
      );
      return;
    }

    // خطوة 2: المستوى الدراسي
    if (state.currentStep == 2 && state.studyLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your target degree level')),
      );
      return;
    }

    // خطوة 3: التخصص (تم ضبطها على fieldOfInterest)
    if (state.currentStep == 3 && state.fieldOfInterest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your major field of study'),
        ),
      );
      return;
    }

    // خطوة 4: سؤال الـ IELTS
    // لو معندوش آيلتس، ينط علطول لخطوة الـ GPA (رقم 6) ويتخطى خطوة السكور
    if (state.currentStep == 4 && state.hasIELTS == false) {
      _pageController.animateToPage(
        6,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // خطوة 6: الـ GPA والـ Scale
    if (state.currentStep == 6) {
      final scale = state.gpaScale.isNotEmpty ? state.gpaScale : '4.0 Scale';

      if (state.gpa == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your GPA / Score')),
        );
        return;
      }

      if (scale == '4.0 Scale' && state.gpa > 4.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPA cannot be greater than 4.0')),
        );
        return;
      } else if (scale == '5.0 Scale' && state.gpa > 5.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPA cannot be greater than 5.0')),
        );
        return;
      } else if (scale == '100% Percentage' && state.gpa > 100.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Percentage cannot exceed 100%')),
        );
        return;
      }
    }

    // خطوة 7: الميزانية
    if (state.currentStep == 7 && state.tuitionBudget.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred budget range'),
        ),
      );
      return;
    }

    // خطوة 8: الأهداف
    if (state.currentStep == 8 && state.studentGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one study goal')),
      );
      return;
    }

    // الرفع لـ Supabase لو في آخر خطوة
    if (state.currentStep == _totalSteps - 1) {
      final Map<String, dynamic> collectedData = {
        'targetCountry': state.targetCountry, // 👈 غيرناها لـ camelCase
        'degreeLevel': state.studyLevel, // 👈 غيرناها لـ camelCase
        'targetMajor': state.fieldOfInterest, // 👈 غيرناها لـ camelCase
        'hasIelts': state.hasIELTS, // 👈 غيرناها لـ camelCase
        'ieltsScore': state.hasIELTS
            ? state.ieltsScore
            : null, // 👈 غيرناها لـ camelCase
        'gpa': state.gpa, // 👈 دي تمام
        'gpaScale': state.gpaScale,
        'budgetRange': state.tuitionBudget, // 👈 غيرناها لـ camelCase
        'goals': state.studentGoals,
      };

      // وبكده لما تبعت الـ Map دي للـ RegisterScreen، الكود بتاعك هيشتغل بدون أي تعديلات!
      context.push('/register', extra: collectedData);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
