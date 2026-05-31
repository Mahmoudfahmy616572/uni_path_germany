import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/auth_repository.dart';
import 'logout_state.dart';

class LogoutCubit extends Cubit<LogoutState> {
  final AuthRepository authRepository;

  LogoutCubit(this.authRepository) : super(LogoutInitial());

  Future<void> logout() async {
    emit(LogoutLoading());
    try {
      await authRepository.logout();

      // نتأكد إن الـ Cubit لسه مفتوح قبل ما نبعت الحالة
      if (!isClosed) {
        emit(LogoutSuccess());
      }
    } catch (e) {
      // وهنا كمان نتأكد
      if (!isClosed) {
        emit(LogoutError(e.toString()));
      }
    }
  }
}
