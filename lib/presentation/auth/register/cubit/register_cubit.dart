import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/universities_repository.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository authRepository;
  final UniversitiesRepository universitiesRepository;

  RegisterCubit(this.authRepository, this.universitiesRepository)
    : super(RegisterInitial());

  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
    String? phone,
    double? gpa,
    double? maxGpa,
    double? minGpa,
    bool? hasMoi,
    bool? hasIelts,
    double? ieltsScore,
    String? targetMajor,
    required String intake,
    required String languagePreference, // 🎯 الحقل الجديد
    String? degreeLevel, // 🎯 Added degree level
  }) async {
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
        print("❌ Profile Sync Error (Non-blocking): $profileError");
      }

      // 🎯 النجاح
      if (!isClosed) {
        emit(RegisterSuccess());
      }
    } catch (e) {
      if (!isClosed) {
        String errorMessage = e.toString().replaceAll('Exception:', '').trim();
        
        // LOG THE ACTUAL ERROR FOR DEBUGGING
        print('🔴 REGISTER ERROR: $errorMessage');
        
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
}
