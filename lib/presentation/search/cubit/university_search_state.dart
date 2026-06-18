import 'package:equatable/equatable.dart';

import '../../../domain/entities/university_entity.dart';

abstract class UniversitySearchState extends Equatable {
  const UniversitySearchState();
  @override
  List<Object?> get props => [];
}

class UniversitySearchInitial extends UniversitySearchState {}

class UniversitySearchLoading extends UniversitySearchState {}

class UniversitySearchLoaded extends UniversitySearchState {
  final List<UniversityEntity> allResults;
  final List<UniversityEntity> filteredResults; // الجامعات المطابقة

  // فلاتر المستخدم الحالية
  final String selectedIntake;
  final String selectedDegree;
  final String selectedMajor;
  final bool requiresIelts;
  final bool acceptsMoi;
  final double maxTuition;
  final String selectedLanguage;
  final String selectedLocation;

  const UniversitySearchLoaded({
    required this.allResults,
    required this.filteredResults,
    required this.selectedIntake,
    required this.selectedDegree,
    required this.selectedMajor,
    required this.requiresIelts,
    required this.acceptsMoi,
    required this.maxTuition,
    required this.selectedLanguage,
    this.selectedLocation = 'All',
  });

  @override
  List<Object?> get props => [
    allResults,
    filteredResults,
    selectedIntake,
    selectedDegree,
    selectedMajor,
    requiresIelts,
    acceptsMoi,
    maxTuition,
    selectedLanguage,
    selectedLocation,
  ];
}

class UniversitySearchError extends UniversitySearchState {
  final String message;
  const UniversitySearchError(this.message);
  @override
  List<Object?> get props => [message];
}
