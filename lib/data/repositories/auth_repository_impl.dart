import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth/auth_service.dart';
import '../../core/services/services_locator.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> login({
    required String emailOrUsername,
    required String password,
  }) async {
    await remoteDataSource.login(
      emailOrUsername: emailOrUsername,
      password: password,
    );
    // Cache admin status after login
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await remoteDataSource.getCurrentUserProfile(user.id);
        final userEntity = UserModel.fromJson(profile);
        sl<AuthService>().cachedIsAdmin = userEntity.role == 'admin';
      } catch (e) {
        log.e('Failed to cache admin status after login: $e');
      }
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String username,
    String? phone,
  }) async {
    await remoteDataSource.register(
      email: email,
      password: password,
      username: username,
      phone: phone,
      targetCountry: 'Germany',
    );
  }

  @override
  Future<void> logout() async => await remoteDataSource.logout();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final data = await remoteDataSource.getCurrentUserProfile(user.id);
    final userEntity = UserModel.fromJson(data);
    sl<AuthService>().cachedIsAdmin = userEntity.role == 'admin';
    return userEntity;
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await remoteDataSource.updateProfile(userId: userId, updates: updates);
  }

  @override
  Future<void> deleteAccount() async {
    await remoteDataSource.deleteAccount();
  }

  @override
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await remoteDataSource.signInWithOAuth(provider);
  }

  @override
  Future<void> resetPassword(String email) async {
    await remoteDataSource.resetPassword(email);
  }
}
