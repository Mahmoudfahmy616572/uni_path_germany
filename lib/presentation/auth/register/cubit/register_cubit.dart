import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/auth_repository.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository authRepository;

  RegisterCubit(this.authRepository) : super(RegisterInitial());

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    emit(RegisterLoading());
    try {
      await authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      emit(RegisterSuccess());
    } catch (e) {
      emit(RegisterError(e.toString()));
    }
  }
}
