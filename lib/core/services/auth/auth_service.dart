import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/logger.dart';
import 'auth_state_enum.dart';

class AuthService {
  final SupabaseClient client;
  bool cachedIsAdmin = false;

  /// Prevents router redirect from /register during OAuth
  static bool isOAuthInProgress = false;

  AuthService(this.client);

  Stream<AuthStatus> get authStateChanges =>
      client.auth.onAuthStateChange.map((data) {
        return data.session != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
      });

  Future<bool> hasValidSession() async {
    final session = client.auth.currentSession;
    if (session == null) return false;
    try {
      final user = client.auth.currentUser;
      return user != null;
    } catch (e) {
      log.e('hasValidSession error: $e');
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
          .maybeSingle().timeout(const Duration(seconds: 10));
      return profile != null &&
          profile['target_major'] != null &&
          profile['target_major'].toString().isNotEmpty &&
          profile['degree_level'] != null &&
          profile['degree_level'].toString().isNotEmpty &&
          profile['intake'] != null &&
          profile['intake'].toString().isNotEmpty;
    } catch (e) {
      log.e('isProfileComplete error: $e');
      return false;
    }
  }
}
