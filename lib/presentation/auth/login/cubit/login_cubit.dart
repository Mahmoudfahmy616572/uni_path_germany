import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../domain/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;
  StreamSubscription? _authSub;

  LoginCubit(this.authRepository) : super(LoginInitial());

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    return super.close();
  }

  Future<void> login({
    required String emailOrUsername,
    required String password,
  }) async {
    if (isClosed) return;
    if (emailOrUsername.isEmpty || password.isEmpty) {
      emit(LoginError("Please fill in all fields"));
      return;
    }

    emit(LoginLoading());
    try {
      await authRepository.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );
      if (!isClosed) emit(LoginSuccess());
    } catch (e) {
      if (isClosed) return;
      final errorStr = e.toString().toLowerCase();

      String errorMessage = "An unexpected error occurred. Please try again.";

      if (errorStr.contains("invalid login credentials") ||
          errorStr.contains("invalid credentials") ||
          errorStr.contains("wrong password")) {
        errorMessage = "Incorrect email/username or password.";
      } else if (errorStr.contains("email_not_confirmed") ||
                 errorStr.contains("email_confirm") ||
                 errorStr.contains("confirm your email") ||
                 errorStr.contains("email_not_verified")) {
        errorMessage = "Please confirm your email before logging in. Check your inbox.";
      } else if (errorStr.contains("network") ||
                 errorStr.contains("connection") ||
                 errorStr.contains("timeout") ||
                 errorStr.contains("socket") ||
                 errorStr.contains("dns")) {
        errorMessage = "Connection failed. Check your internet.";
      } else if (errorStr.contains("too many requests") ||
                 errorStr.contains("rate limit")) {
        errorMessage = "Too many attempts. Please wait a moment.";
      } else if (errorStr.contains("user not found") ||
                 errorStr.contains("no user") ||
                 errorStr.contains("not found")) {
        errorMessage = "No account found with this email/username.";
      } else {
        errorMessage = "Login failed: $errorStr";
      }

      emit(LoginError(errorMessage));
    }
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    try {
      await authRepository.signInWithOAuth(provider);
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
        if (authState.session != null) {
          _authSub?.cancel();
          _authSub = null;
          if (!isClosed) emit(LoginSuccess());
        }
      });
    } catch (e) {
      if (!isClosed) emit(LoginError('OAuth login failed: $e'));
    }
  }

  Future<void> resetPassword(String email) async {
    if (isClosed) return;
    emit(LoginLoading());
    try {
      await authRepository.resetPassword(email);
      if (!isClosed) emit(LoginPasswordResetSent());
    } catch (e) {
      if (!isClosed) emit(LoginError('Failed to send reset email: $e'));
    }
  }
}
