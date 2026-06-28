import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/logger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/services_locator.dart' as di;
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/custom_snack_bar.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';
import '../widgets/budget_step_widget.dart';
import '../widgets/goals_step_widget.dart';
import '../widgets/gpa_step_widget.dart';
import '../widgets/ielts_score_step_widget.dart';
import '../widgets/ielts_step_widget.dart';
import '../widgets/german_cert_step_widget.dart';
import '../widgets/intake_step_widget.dart';
import '../widgets/language_step_widget.dart';
import '../widgets/major_step_widget.dart';
import '../widgets/moi_confirmation_step_widget.dart';
import '../widgets/study_level_step_widget.dart';
import '../widgets/welcome_step_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final int _totalSteps = 12;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  Future<void> _checkExistingProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final authService = di.sl<AuthService>();
    if (!mounted) return;
    final profileComplete = await authService.isProfileComplete();
    if (profileComplete && mounted) {
      context.go('/home');
    }
  }

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
          log.i('ONBOARDING LISTENER: ${state.runtimeType}');
          if (state is OnboardingDataState && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is OnboardingSuccess) {
            log.i('ONBOARDING SUCCESS - going to /home');
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
          final isDark = context.isDark;
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: context.scaffoldBgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: state.currentStep > 0 && !state.isLoading
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: isDark ? AppColors.textMain : AppColors.textDark,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        final step = state.currentStep;
                        if (step == 6 || step == 7) {
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
              actions: state.currentStep == 0
                  ? [
                      TextButton(
                        onPressed: () {
                          final lp = di.sl<LanguageProvider>();
                          lp.setLocale(
                            lp.isArabic
                                ? const Locale('en')
                                : const Locale('ar'),
                          );
                        },
                        child: Text(
                          di.sl<LanguageProvider>().isArabic
                              ? 'EN'
                              : 'العربية',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMain
                                : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ]
                  : null,
            ),
            body: SafeArea(
              child: Column(
                  children: [
                  CurtainDrop(
                    index: 0,
                    child: state.currentStep > 0
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 8.0,
                            ),
                            child: LinearProgressIndicator(
                              value: state.currentStep / (_totalSteps - 1),
                              backgroundColor: context.inputBgColor,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              minHeight: 6.h,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: CurtainDrop(
                      index: 1,
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
                          LanguageStepWidget(cubit: cubit, state: state),
                          IeltsStepWidget(cubit: cubit, state: state),
                          GermanCertStepWidget(cubit: cubit, state: state),
                          IeltsScoreStepWidget(cubit: cubit, state: state),
                          MoiConfirmationStepWidget(
                            cubit: cubit,
                            state: state,
                          ),
                          GpaStepWidget(cubit: cubit, state: state),
                          BudgetStepWidget(cubit: cubit, state: state),
                          GoalsStepWidget(cubit: cubit, state: state),
                        ],
                    ),
                  ),
                  ),
                  CurtainDrop(
                    index: 2,
                    child: state.currentStep == 7 && !state.moiConfirmed
                        ? const SizedBox.shrink()
                        : Padding(
                      padding: EdgeInsets.all(24.r),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56.h,
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
                                log.i('BUTTON PRESSED: Step ${state.currentStep}, isLoading: ${state.isLoading}');
                                _handleNextAction(state, cubit);
                              },
                          child: state.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  _getButtonText(
                                    state.currentStep,
                                    context,
                                  ),
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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

  String _getButtonText(int step, BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    return step == 0
        ? t('btnGetStarted')
        : (step == _totalSteps - 1 ? t('btnLooksGood') : t('btnContinue'));
  }

  void _handleNextAction(OnboardingDataState state, OnboardingCubit cubit) {
    final errorMessage = _validateCurrentStep(state);
    if (errorMessage != null) {
      log.e('ONBOARDING VALIDATION FAILED: $errorMessage');
      CustomSnackBar.show(context, message: errorMessage, isError: true);
      return;
    }

    final step = state.currentStep;

    if (step == 5) {
      if (state.testType == 'moi') {
        _pageController.jumpToPage(8);
        return;
      }
      if (state.testType == 'none') {
        _pageController.jumpToPage(9);
        return;
      }
      if (state.testType == 'ielts' || state.testType == 'toefl') {
        _pageController.jumpToPage(7);
        return;
      }
      // german → normal next to step 6
    }
    if (step == 6 && state.testType == 'german') {
      _pageController.jumpToPage(9);
      return;
    }
    if (step == 7 || step == 8) {
      _pageController.jumpToPage(9);
      return;
    }

    // If Bachelor & hasn't studied university → skip academic average
    if (step == 9 && !_isGraduateLevel(state.studyLevel) && !state.hasStudiedUniversity) {
      _pageController.jumpToPage(10);
      return;
    }

    if (step == _totalSteps - 1) {
      final collectedData = {
        'targetCountry': 'Germany',
        'intake': state.targetIntake,
        'degreeLevel': state.studyLevel,
        'targetMajor': state.fieldOfInterest,
        'languagePreference': state.languagePreference,
        'testType': state.testType,
        'hasIelts': state.testType == 'ielts',
        'ieltsScore': state.testType == 'ielts' ? state.ieltsScore : null,
        'hasToefl': state.testType == 'toefl',
        'toeflScore': state.testType == 'toefl' ? state.ieltsScore : null,
        'hasMoi': state.testType == 'moi',
        'moiConfirmed': state.moiConfirmed,
        'token': state.token,
        'hasNone': state.testType == 'none',
        'hasGermanCert': state.hasGermanCert,
        'germanCertType': state.germanCertType,
        'germanCertLevel': state.germanCertLevel,
        'gpa': state.gpa,
        'gpaScale': state.gpaScale,
        'academicAverage': state.hasStudiedUniversity ? state.academicAverage : null,
        'highSchoolScore': state.hasStudiedUniversity ? null : state.highSchoolScore,
        'budgetRange': state.tuitionBudget,
        'goals': state.studentGoals,
      };
      log.i('Navigating to /register with data: $collectedData');
      context.push('/register', extra: collectedData);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    }
  }

  bool _isGraduateLevel(String level) {
    return level == "Master's Degree" || level == 'PhD / Doctorate' || level == 'Graduate School';
  }

  String? _validateCurrentStep(OnboardingDataState state) {
    final t = AppLocalizations.of(context).translate;
    switch (state.currentStep) {
      case 1:
        if (state.targetIntake.isEmpty) return t('valIntake');
        break;
      case 2:
        if (state.studyLevel.isEmpty) return t('valStudyLevel');
        break;
      case 3:
        if (state.fieldOfInterest.isEmpty) return t('valMajor');
        break;
      case 4:
        if (state.languagePreference.isEmpty) return t('valLanguage');
        break;
      case 5:
        if (state.testType.isEmpty) return t('valTestType');
        break;
      case 6:
        if (state.testType == 'german' && (state.germanCertType.isEmpty || state.germanCertLevel.isEmpty)) {
          return 'Please select a certificate type and level';
        }
        break;
      case 7:
        if ((state.testType == 'ielts' || state.testType == 'toefl') && state.ieltsScore <= 0) {
          return t('valScore');
        }
        break;
      case 8:
        if (!state.moiConfirmed) return t('valMoiConfirm');
        break;
      case 9:
        if (_isGraduateLevel(state.studyLevel)) {
          if (state.gpa <= 0) return t('valGpa');
          if (state.gpaScale.isEmpty) return t('valGpaScale');
        }
        break;
      case 10:
        if (state.tuitionBudget.isEmpty) return t('valBudget');
        break;
    }
    return null;
  }
}
