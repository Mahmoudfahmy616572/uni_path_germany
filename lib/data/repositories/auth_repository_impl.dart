import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';
import '../sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> login(String email, String password) async {
    try {
      await remoteDataSource.login(email, password);
    } catch (e) {
      throw Exception("Login Failed: ${e.toString()}");
    }
  }

  @override
  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    // افترضنا إنك معرف الـ supabase كـ variable جوه الكلاس أو بتستخدم Supabase.instance
    final supabase = Supabase.instance.client;

    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'phone': phone},
    );
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      throw Exception("Logout Failed: ${e.toString()}");
    }
  }
}
