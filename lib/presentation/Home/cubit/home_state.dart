import '../../../../domain/entities/university_entity.dart';

abstract class HomeState {}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final int matchScore;
  final List<UniversityEntity> recommendations; // بنستخدم Entity هنا

  HomeLoaded({
    required this.matchScore,
    required this.recommendations,
  });
}
class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}