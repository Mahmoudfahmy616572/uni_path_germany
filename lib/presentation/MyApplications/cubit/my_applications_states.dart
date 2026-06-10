import 'package:equatable/equatable.dart';

import '../../../domain/entities/university_entity.dart';

abstract class MyApplicationsState extends Equatable {
  const MyApplicationsState();
  @override
  List<Object?> get props => [];
}

class MyApplicationsInitial extends MyApplicationsState {}

class MyApplicationsLoading extends MyApplicationsState {}

class MyApplicationsLoaded extends MyApplicationsState {
  final List<UniversityEntity> allApplications;
  final List<UniversityEntity> filteredApplications;
  final String activeFilter;
  final Map<String, int> statusCounts;

  const MyApplicationsLoaded({
    required this.allApplications,
    required this.filteredApplications,
    required this.activeFilter,
    required this.statusCounts,
  });

  MyApplicationsLoaded copyWith({
    List<UniversityEntity>? allApplications,
    List<UniversityEntity>? filteredApplications,
    String? activeFilter,
    Map<String, int>? statusCounts,
  }) {
    return MyApplicationsLoaded(
      allApplications: allApplications ?? this.allApplications,
      filteredApplications: filteredApplications ?? this.filteredApplications,
      activeFilter: activeFilter ?? this.activeFilter,
      statusCounts: statusCounts ?? this.statusCounts,
    );
  }

  @override
  List<Object?> get props => [
    allApplications,
    filteredApplications,
    activeFilter,
    statusCounts,
  ];
}

class MyApplicationsError extends MyApplicationsState {
  final String message;
  const MyApplicationsError(this.message);
  @override
  List<Object?> get props => [message];
}
