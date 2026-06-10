import 'package:supabase_flutter/supabase_flutter.dart';

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
    return UserModel.fromJson(data);
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await remoteDataSource.updateProfile(userId: userId, updates: updates);
  }
}
