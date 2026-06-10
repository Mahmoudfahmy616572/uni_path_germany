import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/auth_repository.dart';
import 'logout_state.dart';

class LogoutCubit extends Cubit<LogoutState> {
  final AuthRepository authRepository;

  LogoutCubit(this.authRepository) : super(LogoutInitial());

  Future<void> logout() async {
    // 🛡️ تأمين: إذا كان التطبيق يقوم بعملية تسجيل خروج بالفعل، نخرج
    if (state is LogoutLoading) return;

    emit(LogoutLoading());

    try {
      await authRepository.logout();

      if (!isClosed) {
        emit(LogoutSuccess());
      }
    } catch (e) {
      // 🛡️ معالجة الخطأ: تحويل الخطأ التقني لرسالة مفهومة
      if (!isClosed) {
        emit(LogoutError("تعذر تسجيل الخروج، يرجى المحاولة مرة أخرى."));
      }
    }
  }
}
