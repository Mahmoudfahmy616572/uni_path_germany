import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/universities_repository.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository authRepository;
  final UniversitiesRepository universitiesRepository;
  StreamSubscription? _authSub;

  RegisterCubit(this.authRepository, this.universitiesRepository)
    : super(RegisterInitial());

  @override
  Future<void> close() async {
    AuthService.isOAuthInProgress = false;
    await _authSub?.cancel();
    return super.close();
  }

  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
    String? phone,
    double? gpa,
    double? academicAverage,
    double? highSchoolScore,
    double? maxGpa,
    double? minGpa,
    bool? hasMoi,
    bool? hasIelts,
    double? ieltsScore,
    String? targetMajor,
    required String intake,
    required String languagePreference,
    String? degreeLevel,
  }) async {
    AuthService.isOAuthInProgress = false;
    // حماية أساسية
    if (email.isEmpty || password.length < 6) {
      if (!isClosed) {
        emit(RegisterError("تأكد من صحة البريد وكلمة المرور (6 رموز فأكثر)"));
      }
      return;
    }

    if (!isClosed) emit(RegisterLoading());

    try {
      // 1️⃣ الخطوة الأولى: إنشاء الحساب في Auth
      await authRepository.register(
        email: email,
        password: password,
        username: username,
        phone: phone,
      );

      // ⚠️ بعد إنشاء الحساب، السوبر بيز قد يقوم بتسجيل الدخول تلقائياً
      // ويحدث Redirect، لذا نستخدم حماية isClosed في كل الخطوات القادمة

      // 2️⃣ الخطوة الثانية: إكمال بيانات البروفايل (GPA, Intake, Language, etc.)
      try {
        await universitiesRepository.completeStudentProfile(
          gpa: gpa ?? 0.0,
          academicAverage: academicAverage,
          highSchoolScore: highSchoolScore,
          maxGpa: maxGpa ?? 4.0,
          minGpa: minGpa ?? 1.0,
          hasMoi: hasMoi ?? false,
          hasIelts: hasIelts ?? false,
          ieltsScore: ieltsScore ?? 0.0,
          targetMajor: targetMajor ?? '',
          intake: intake,
          languagePreference: languagePreference, // 🎯 تمرير اللغة
          degreeLevel: degreeLevel ?? '', // 🎯 تمرير مستوى الدرجة
        );
      } catch (profileError) {
        log.e("Profile Sync Error (Non-blocking): $profileError");
      }

      // 🎯 النجاح
      if (!isClosed) {
        emit(RegisterSuccess());
      }
    } catch (e) {
      if (!isClosed) {
        String errorMessage = e.toString().replaceAll('Exception:', '').trim();
        
        // LOG THE ACTUAL ERROR FOR DEBUGGING
        log.e('Register error: $errorMessage');
        
        // Handle specific Supabase errors
        final lowerError = errorMessage.toLowerCase();
        if (lowerError.contains('email_confirmation_required') ||
            lowerError.contains('email_confirm') ||
            lowerError.contains('confirm your email') ||
            lowerError.contains('email_not_confirmed')) {
          errorMessage = 'Please check your email and confirm your account before logging in.';
        } else if (lowerError.contains("already exists") ||
                   lowerError.contains("duplicate") ||
                   lowerError.contains("user_already_exists") ||
                   lowerError.contains("email_exists")) {
          errorMessage = 'This email or username is already registered. Try logging in.';
        } else if (lowerError.contains("weak password") ||
                   lowerError.contains("password_too_short") ||
                   lowerError.contains("password should be at least")) {
          errorMessage = 'Password is too weak. Use at least 6 characters.';
        } else if (lowerError.contains("invalid email") ||
                   lowerError.contains("email format") ||
                   lowerError.contains("malformed")) {
          errorMessage = 'Please enter a valid email address.';
        } else if (lowerError.contains("network") ||
                   lowerError.contains("connection") ||
                   lowerError.contains("timeout") ||
                   lowerError.contains("socket") ||
                   lowerError.contains("dns")) {
          errorMessage = 'Connection failed. Check your internet and try again.';
        } else if (lowerError.contains("row level security") ||
                   lowerError.contains("permission denied") ||
                   lowerError.contains("policy") ||
                   lowerError.contains("rls")) {
          errorMessage = 'Server configuration error. Please contact support.';
        } else if (lowerError.contains("username") && lowerError.contains("taken")) {
          errorMessage = 'This username is already taken. Choose another.';
        } else if (lowerError.contains("signup_disabled") ||
                   lowerError.contains("registration disabled")) {
          errorMessage = 'Registration is currently disabled. Contact support.';
        } else {
          // Include actual error for debugging
          errorMessage = 'Registration failed: $errorMessage';
        }
        
        emit(RegisterError(errorMessage));
      }
    }
  }

  Future<void> signInWithOAuth(
    OAuthProvider provider, {
    Map<String, dynamic>? profileData,
  }) async {
    try {
      AuthService.isOAuthInProgress = true;
      log.i('OAuth: opening browser for $provider');
      await authRepository.signInWithOAuth(provider);
      log.i('OAuth: browser opened, setting up auth listener');
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((authState) async {
        log.i('OAuth: auth event=${authState.event} session=${authState.session != null}');
        if (authState.session != null) {
          _authSub?.cancel();
          _authSub = null;
          log.i('OAuth: session found, profileData=${profileData != null}');
          if (profileData != null) {
            await _doSaveProfile(profileData);
          }
          AuthService.isOAuthInProgress = false;
          if (!isClosed) emit(RegisterSuccess());
        }
      });
    } catch (e) {
      AuthService.isOAuthInProgress = false;
      if (!isClosed) emit(RegisterError('OAuth registration failed: $e'));
    }
  }

  Future<void> _doSaveProfile(Map<String, dynamic> profileData) async {
    try {
      log.i('OAuth: saving profile gpa=${profileData['gpa']} major=${profileData['targetMajor']}');
      await universitiesRepository.completeStudentProfile(
        gpa: (profileData['gpa'] as num?)?.toDouble() ?? 0.0,
        academicAverage: (profileData['academicAverage'] as num?)?.toDouble(),
        highSchoolScore: (profileData['highSchoolScore'] as num?)?.toDouble(),
        maxGpa: (profileData['maxGpa'] as num?)?.toDouble() ?? 4.0,
        minGpa: (profileData['minGpa'] as num?)?.toDouble() ?? 1.0,
        hasMoi: profileData['hasMoi'] as bool? ?? false,
        hasIelts: profileData['hasIelts'] as bool? ?? false,
        ieltsScore: (profileData['ieltsScore'] as num?)?.toDouble(),
        targetMajor: profileData['targetMajor'] as String? ?? '',
        intake: profileData['intake'] as String? ?? 'Both Semesters',
        languagePreference: profileData['languagePreference'] as String? ?? 'English',
        degreeLevel: profileData['degreeLevel'] as String? ?? '',
      );
      log.i('OAuth: profile saved successfully');
    } catch (e) {
      log.e('OAuth: profile save failed: $e');
    }
  }
}
