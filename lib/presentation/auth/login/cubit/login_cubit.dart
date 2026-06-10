import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;

  LoginCubit(this.authRepository) : super(LoginInitial());

  Future<void> login({
    required String emailOrUsername,
    required String password,
  }) async {
    // 🛡️ حماية: منع الدخول ببيانات فارغة
    if (emailOrUsername.isEmpty || password.isEmpty) {
      emit(LoginError("الرجاء ملء جميع الحقول"));
      return;
    }

    emit(LoginLoading());
    try {
      await authRepository.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );
      emit(LoginSuccess());
    } catch (e) {
      // 🛡️ معالجة الأخطاء الذكية:
      // هنا نقوم بتحويل الخطأ التقني لرسالة مفهومة للمستخدم
      String errorMessage = "حدث خطأ غير متوقع، حاول لاحقاً";

      if (e.toString().contains("Invalid login credentials")) {
        errorMessage = "البريد الإلكتروني أو كلمة المرور غير صحيحة";
      } else if (e.toString().contains("Connection")) {
        errorMessage = "تأكد من اتصالك بالإنترنت";
      }

      emit(LoginError(errorMessage));
    }
  }
}
