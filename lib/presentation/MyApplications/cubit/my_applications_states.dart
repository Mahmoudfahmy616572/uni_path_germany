import '../../../data/models/university_model.dart';

abstract class MyApplicationsState {}

class MyApplicationsInitial extends MyApplicationsState {}

class MyApplicationsLoading extends MyApplicationsState {}

class MyApplicationsLoaded extends MyApplicationsState {
  final List<UniversityModel> allApplications;
  final List<UniversityModel> filteredApplications;
  final String activeFilter; // 'all', 'saved', 'preparing', 'applied', etc.
  final Map<String, int> statusCounts;

  MyApplicationsLoaded({
    required this.allApplications,
    required this.filteredApplications,
    required this.activeFilter,
    required this.statusCounts,
  });
  List<Object?> get props => [
    allApplications,
    filteredApplications,
    activeFilter,
    statusCounts,
  ];
}

class MyApplicationsError extends MyApplicationsState {
  final String message;
  MyApplicationsError(this.message);
}
