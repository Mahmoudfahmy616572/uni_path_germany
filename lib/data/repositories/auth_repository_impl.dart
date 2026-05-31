import '../../domain/repositories/auth_repository.dart';
import '../sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      await remoteDataSource.login(emailOrUsername, password);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String username,
    String? phone,
    required String targetCountry,
  }) async {
    try {
      await remoteDataSource.register(
        email,
        password,
        username,
        phone,
        targetCountry: targetCountry,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      throw Exception("Logout Failed: ${e.toString()}");
    }
  }
}
