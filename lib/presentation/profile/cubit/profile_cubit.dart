import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/applications_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository authRepository;
  final ApplicationsRepository applicationsRepository;

  ProfileCubit(this.authRepository, this.applicationsRepository)
    : super(ProfileInitial());

  // 🎯 جلب الكيان الحالي بسهولة
  UserEntity get getUserEntity => (state is ProfileLoaded)
      ? (state as ProfileLoaded).user
      : UserEntity(id: '', email: '', name: 'User');

  Future<void> getUserProfile() async {
    if (isClosed) return;
    emit(ProfileLoading());
    try {
      final user = await authRepository.getCurrentUser();
      final apps = await applicationsRepository.getMyApplications();

      if (user != null && !isClosed) {
        double totalMatch = apps.isEmpty
            ? 0
            : apps.map((e) => e.matchPercentage).reduce((a, b) => a + b) /
                  apps.length;
        emit(
          ProfileLoaded(
            user: user,
            savedCount: apps.length,
            appliedCount: apps.where((e) => e.status == 'applied').length,
            averageMatch: totalMatch.round(),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfileData({
    required Map<String, dynamic> updates,
    String? newEmail,
  }) async {
    final currentState = state;
    emit(ProfileLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        await authRepository.updateProfile(userId: user.id, updates: updates);
        emit(ProfileUpdateSuccess()); // إشارة إغلاق الشاشة
        await getUserProfile();
      }
    } catch (e) {
      if (!isClosed) emit(ProfileError(e.toString()));
    }
  }
}
