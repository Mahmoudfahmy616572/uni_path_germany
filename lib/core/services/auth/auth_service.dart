import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_state_enum.dart'; // اعمل import للـ enum اللي لسه عاملينه

class AuthService {
  final SupabaseClient client;

  AuthService(this.client);

  Stream<AuthStatus> get authStateChanges =>
      client.auth.onAuthStateChange.map((data) {
        return data.session != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
      });
}
