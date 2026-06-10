import 'package:equatable/equatable.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingDataState extends OnboardingState {
  final int currentStep;
  final String targetIntake;
  final String studyLevel;
  final String fieldOfInterest;
  final String languagePreference; // 🎯 الحقل الجديد المضاف
  final bool hasIELTS;
  final double ieltsScore;
  final double gpa;
  final String gpaScale;
  final String tuitionBudget;
  final List<String> studentGoals;
  final bool isLoading;
  final String? errorMessage;

  const OnboardingDataState({
    this.currentStep = 0,
    this.targetIntake = '',
    this.studyLevel = '',
    this.fieldOfInterest = '',
    this.languagePreference = 'English',
    this.hasIELTS = false,
    this.ieltsScore = 0.0,
    this.gpa = 0.0,
    this.gpaScale = '4.0',
    this.tuitionBudget = '',
    this.studentGoals = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingDataState copyWith({
    int? currentStep,
    String? targetIntake,
    String? studyLevel,
    String? fieldOfInterest,
    String? languagePreference,
    bool? hasIELTS,
    double? ieltsScore,
    double? gpa,
    String? gpaScale,
    String? tuitionBudget,
    List<String>? studentGoals,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingDataState(
      currentStep: currentStep ?? this.currentStep,
      targetIntake: targetIntake ?? this.targetIntake,
      studyLevel: studyLevel ?? this.studyLevel,
      fieldOfInterest: fieldOfInterest ?? this.fieldOfInterest,
      languagePreference: languagePreference ?? this.languagePreference,
      hasIELTS: hasIELTS ?? this.hasIELTS,
      ieltsScore: ieltsScore ?? this.ieltsScore,
      gpa: gpa ?? this.gpa,
      gpaScale: gpaScale ?? this.gpaScale,
      tuitionBudget: tuitionBudget ?? this.tuitionBudget,
      studentGoals: studentGoals ?? this.studentGoals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    targetIntake,
    studyLevel,
    fieldOfInterest,
    languagePreference,
    hasIELTS,
    ieltsScore,
    gpa,
    gpaScale,
    tuitionBudget,
    studentGoals,
    isLoading,
    errorMessage,
  ];
}

class OnboardingSuccess extends OnboardingState {}

class OnboardingFailure extends OnboardingState {
  final String errorMessage;

  const OnboardingFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
