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

  // 🎯 دالة الـ copyWith لتحديث حقول معينة (مثل حقل الـ filteredApplications عند البحث)
  MyApplicationsLoaded copyWith({
    List<UniversityModel>? allApplications,
    List<UniversityModel>? filteredApplications,
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
