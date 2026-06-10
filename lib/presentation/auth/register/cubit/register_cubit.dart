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
  }) async {
    // حماية أساسية
    if (email.isEmpty || password.length < 6) {
      if (!isClosed)
        emit(RegisterError("تأكد من صحة البريد وكلمة المرور (6 رموز فأكثر)"));
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
        if (errorMessage.contains("already exists")) {
          errorMessage = "هذا البريد الإلكتروني أو اسم المستخدم مأخوذ بالفعل.";
        }
        emit(RegisterError(errorMessage));
      }
    }
  }
}
