// lib/features/university_details/cubit/university_details_state.dart
abstract class UniversityDetailsState {}

class UniversityDetailsInitial extends UniversityDetailsState {}

class UniversitySaveStatus extends UniversityDetailsState {
  final bool isSaved;
  final bool isLoading;
  final String? errorMessage;
  final bool isFromAction; 

  UniversitySaveStatus({
    required this.isSaved,
    this.isLoading = false,
    this.errorMessage,
    this.isFromAction = false,
  });
}

class UniversitySavingLoading extends UniversityDetailsState {}

class UniversitySavedSuccess extends UniversityDetailsState {}

class UniversitySavingError extends UniversityDetailsState {
  final String message;
  UniversitySavingError(this.message);
}
