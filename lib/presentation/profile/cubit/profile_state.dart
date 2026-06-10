import '../../../domain/entities/user_entity.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserEntity user;
  final int savedCount;
  final int appliedCount;
  final int averageMatch;
  ProfileLoaded({
    required this.user,
    required this.savedCount,
    required this.appliedCount,
    required this.averageMatch,
  });
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}
