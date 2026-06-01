import '../../../data/models/university_model.dart';

abstract class UniversitySearchState {}

class UniversitySearchInitial extends UniversitySearchState {}

class UniversitySearchLoading extends UniversitySearchState {}

class UniversitySearchLoaded extends UniversitySearchState {
  final List<UniversityModel> allResults;
  final List<UniversityModel> filteredResults;

  final String selectedCountry;
  final String selectedDegree;
  final String selectedMajor;
  final bool requiresIelts;
  final bool acceptsMoi; // 🔥 الـ MOI الجديد هنا
  final double maxTuition;
  final String selectedLanguage;

  UniversitySearchLoaded({
    required this.allResults,
    required this.filteredResults,
    required this.selectedCountry,
    required this.selectedDegree,
    required this.selectedMajor,
    required this.requiresIelts,
    required this.acceptsMoi, // 🔥
    required this.maxTuition,
    required this.selectedLanguage,
  });
}

class UniversitySearchError extends UniversitySearchState {
  final String message;
  UniversitySearchError(this.message);
}
