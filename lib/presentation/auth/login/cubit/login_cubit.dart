import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;

  LoginCubit(this.authRepository) : super(LoginInitial());

  // تعديل اسم الباراميتر الأول ليكون معبراً عن الإيميل أو اليوزر نيم
  Future<void> login({
    required String emailOrUsername,
    required String password,
  }) async {
    emit(LoginLoading());
    try {
      // مناداة الـ Repository باستخدام الـ Named Parameters المحدثة
      await authRepository.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );
      emit(LoginSuccess());
    } catch (e) {
      emit(LoginError(e.toString()));
    }
  }
}
