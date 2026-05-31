import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/universities_repository.dart'; // 🔥 عملنا import للـ repository الجديد
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository authRepository;
  final UniversitiesRepository
  universitiesRepository; // 🔥 ضفنا الاعتمادية دي هنا

  // الـ Constructor بياخد الـ الاثنين repositories دلوقتي
  RegisterCubit(this.authRepository, this.universitiesRepository)
    : super(RegisterInitial());

  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
    String? phone,
    double? gpa,
    double? maxGpa, // 👈 حقل جديد
    double? minGpa, // 👈 حقل جديد
    bool? hasMoi,
    bool? hasIelts,
    double? ieltsScore,
    String? targetMajor,
    required String targetCountry,
  }) async {
    emit(RegisterLoading());
    try {
      // 1️⃣ الخطوة الأولى: إنشاء الحساب الأساسي في الـ Auth
      await authRepository.register(
        email: email,
        password: password,
        username: username,
        phone: phone,
        targetCountry: targetCountry,
      );

      // 2️⃣ الخطوة الثانية: رفع بيانات بروفايل الطالب والماتشينج فوراً بعد نجاح الـ Auth
      // بنشيك لو فيه داتا تخصص أو GPA مبعوتة نرفعها، لو مفيش بنباصي الـ defaults
      await universitiesRepository.completeStudentProfile(
        gpa: gpa ?? 0.0,
        maxGpa: maxGpa ?? 4.0,
        minGpa: minGpa ?? 1.0,
        hasMoi: hasMoi ?? false,
        hasIelts: hasIelts ?? false,
        ieltsScore: ieltsScore,
        targetMajor: targetMajor ?? '',
        targetCountry: targetCountry,
      );

      emit(RegisterSuccess());
    } catch (e) {
      emit(RegisterError(e.toString()));
    }
  }
}
