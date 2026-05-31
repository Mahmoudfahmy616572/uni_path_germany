import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(String emailOrUsername, String password);
  Future<AuthResponse> register(
    String email,
    String password,
    String username,
    String? phone, {
    required String targetCountry,
  });
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;
  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<AuthResponse> login(String emailOrUsername, String password) async {
    final cleanInput = emailOrUsername.trim();
    if (cleanInput.isEmpty || password.trim().isEmpty) {
      throw Exception(
        'برجاء إدخال البريد الإلكتروني (أو اسم المستخدم) وكلمة المرور.',
      );
    }
    String targetEmail = cleanInput;
    if (!targetEmail.contains('@')) {
      final userData = await client
          .from('profiles')
          .select('email')
          .eq('username', targetEmail)
          .maybeSingle();
      if (userData == null) throw Exception('اسم المستخدم هذا غير مسجل لدينا.');
      targetEmail = userData['email'];
    }
    return await client.auth.signInWithPassword(
      email: targetEmail,
      password: password,
    );
  }

  @override
  Future<AuthResponse> register(
    String email,
    String password,
    String username,
    String? phone, {
    required String targetCountry,
  }) async {
    if (email.trim().isEmpty ||
        password.trim().isEmpty ||
        username.trim().isEmpty) {
      throw Exception('جميع الحقول الأساسية مطلوبة.');
    }

    final checkUsername = await client
        .from('profiles')
        .select('username')
        .eq('username', username.trim())
        .maybeSingle();
    if (checkUsername != null)
      throw Exception('اسم المستخدم هذا مأخوذ بالفعل، اختر اسماً آخر.');

    final cleanPhone = (phone == null || phone.trim().isEmpty)
        ? null
        : phone.trim();

    final AuthResponse response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      phone: cleanPhone,
      data: {
        'username': username.trim(),
        'phone': cleanPhone,
        'target_country': targetCountry,
      },
    );

    final user = response.user;
    if (user != null) {
      await client
          .from('profiles')
          .update({
            'username': username.trim(),
            'phone': cleanPhone,
            'target_country': targetCountry,
          })
          .eq('id', user.id);
    }
    return response;
  }

  @override
  Future<void> logout() async {
    await client.auth.signOut();
  }
}
