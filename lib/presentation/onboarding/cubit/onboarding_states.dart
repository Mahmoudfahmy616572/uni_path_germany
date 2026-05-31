abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingDataState extends OnboardingState {
  final int currentStep;
  final String targetCountry; // شاشة 1 (Where do you want to study)
  final String studyLevel; // شاشة 2 (What level of study)
  final String fieldOfInterest; // شاشة 3 (Field of interest)
  final bool hasIELTS; // شاشة 4 (Do you have IELTS)
  final double ieltsScore; // شاشة 4a (IELTS Score Band)
  final double gpa; // شاشة 5 (GPA / CGPA)
  final String gpaScale; // شاشة 5 (4.0 Scale or 10.0 Scale)
  final String tuitionBudget; // شاشة 6 (Tuition Budget)
  final List<String> studentGoals; // شاشة 7 (What are your goals)
  final bool isLoading;
  final String? errorMessage;

  OnboardingDataState({
    this.currentStep = 0,
    this.targetCountry = '',
    this.studyLevel = '',
    this.fieldOfInterest = '',
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
    String? targetCountry,
    String? studyLevel,
    String? fieldOfInterest,
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
      targetCountry: targetCountry ?? this.targetCountry,
      studyLevel: studyLevel ?? this.studyLevel,
      fieldOfInterest: fieldOfInterest ?? this.fieldOfInterest,
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
}

// State خاص بالنجاح النهائي للانتقال لشاشة الـ Home
class OnboardingSuccess extends OnboardingState {}
