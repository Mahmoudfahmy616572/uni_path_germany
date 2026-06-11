import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_state_enum.dart';

class AuthService {
  final SupabaseClient client;

  AuthService(this.client);

  Stream<AuthStatus> get authStateChanges =>
      client.auth.onAuthStateChange.map((data) {
        return data.session != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
      });

  // Check if user has valid session (for app startup)
  Future<bool> hasValidSession() async {
    final session = client.auth.currentSession;
    if (session == null) return false;
    try {
      // Verify session is still valid by getting user
      final user = client.auth.currentUser;
      return user != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isProfileComplete() async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    try {
      final profile = await client
          .from('profiles')
          .select('target_major, degree_level, intake')
          .eq('id', user.id)
          .maybeSingle();
      return profile != null &&
          profile['target_major'] != null &&
          profile['target_major'].toString().isNotEmpty &&
          profile['degree_level'] != null &&
          profile['degree_level'].toString().isNotEmpty &&
          profile['intake'] != null &&
          profile['intake'].toString().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
