import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(String email, String password);
  Future<void> logout(); // إضافة ميثود الـ logout
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<AuthResponse> login(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> register(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> logout() async {
    // الـ signOut في supabase بيخرج اليوزر من الـ Local storage
    // وبيمسح الـ Token بتاعته
    await client.auth.signOut();
  }
}
