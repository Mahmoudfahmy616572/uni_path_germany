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
  final String languagePreference;
  final bool hasIELTS;
  final double ieltsScore;
  final String testType;
  final bool moiConfirmed;
  final String token;
  final bool hasMoi;
  final bool noneOfTheAbove;
  final bool hasGermanCert;
  final String germanCertType;
  final String germanCertLevel;
  final double gpa;
  final String gpaScale;
  final double? academicAverage;
  final double? highSchoolScore;
  final bool hasStudiedUniversity;
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
    this.testType = '',
    this.moiConfirmed = false,
    this.token = '',
    this.hasMoi = false,
    this.noneOfTheAbove = false,
    this.hasGermanCert = false,
    this.germanCertType = '',
    this.germanCertLevel = '',
    this.gpa = 0.0,
    this.gpaScale = '4.0',
    this.academicAverage,
    this.highSchoolScore,
    this.hasStudiedUniversity = false,
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
    String? testType,
    bool? moiConfirmed,
    String? token,
    bool? hasMoi,
    bool? noneOfTheAbove,
    bool? hasGermanCert,
    String? germanCertType,
    String? germanCertLevel,
    double? gpa,
    String? gpaScale,
    double? academicAverage,
    double? highSchoolScore,
    bool? hasStudiedUniversity,
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
      testType: testType ?? this.testType,
      moiConfirmed: moiConfirmed ?? this.moiConfirmed,
      token: token ?? this.token,
      hasMoi: hasMoi ?? this.hasMoi,
      noneOfTheAbove: noneOfTheAbove ?? this.noneOfTheAbove,
      hasGermanCert: hasGermanCert ?? this.hasGermanCert,
      germanCertType: germanCertType ?? this.germanCertType,
      germanCertLevel: germanCertLevel ?? this.germanCertLevel,
      gpa: gpa ?? this.gpa,
      gpaScale: gpaScale ?? this.gpaScale,
      academicAverage: academicAverage ?? this.academicAverage,
      highSchoolScore: highSchoolScore ?? this.highSchoolScore,
      hasStudiedUniversity: hasStudiedUniversity ?? this.hasStudiedUniversity,
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
    testType,
    moiConfirmed,
    token,
    hasMoi,
    noneOfTheAbove,
    hasGermanCert,
    germanCertType,
    germanCertLevel,
    gpa,
    gpaScale,
    academicAverage,
    highSchoolScore,
    hasStudiedUniversity,
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
