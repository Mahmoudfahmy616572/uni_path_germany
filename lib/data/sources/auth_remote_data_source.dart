import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login({
    required String emailOrUsername,
    required String password,
  });
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
    String? phone,
    required String targetCountry,
  });
  Future<void> logout();
  Future<Map<String, dynamic>> getCurrentUserProfile(String userId);
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  });

  // 🎯 وظيفة جديدة لتحديث البريد الإلكتروني في Supabase Auth
  Future<void> updateEmail(String newEmail);

  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;
  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<AuthResponse> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final cleanInput = emailOrUsername.trim();
    String targetEmail = cleanInput;
    if (!targetEmail.contains('@')) {
      final userData = await client
          .from('profiles')
          .select('email')
          .eq('username', targetEmail)
          .maybeSingle();
      if (userData == null) throw Exception('User not found');
      targetEmail = userData['email'];
    }
    return await client.auth.signInWithPassword(
      email: targetEmail,
      password: password,
    );
  }

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
    String? phone,
    required String targetCountry,
  }) async {
    final AuthResponse response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'username': username.trim(),
        'phone': phone,
        'target_country': targetCountry,
      },
    );

    if (response.user != null) {
      // Use upsert to create or update profile (handles missing row)
      await client.from('profiles').upsert({
        'id': response.user!.id,
        'email': email.trim(),
        'username': username.trim(),
        'phone': phone,
        'target_country': targetCountry,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    }

    // Check if email confirmation is required
    if (response.session == null && response.user != null) {
      throw Exception('EMAIL_CONFIRMATION_REQUIRED');
    }

    return response;
  }

  @override
  Future<void> logout() async => await client.auth.signOut();

  @override
  Future<Map<String, dynamic>> getCurrentUserProfile(String userId) async {
    final result = await client.from('profiles').select().eq('id', userId).maybeSingle();
    return result ?? <String, dynamic>{};
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await client.from('profiles').update(updates).eq('id', userId);
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await client.auth.updateUser(UserAttributes(email: newEmail));
  }

  @override
  Future<void> deleteAccount() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    await client.from('profiles').delete().eq('id', user.id);
    await client.auth.signOut();
  }
}
