abstract class AuthRepository {
  Future<void> login({
    required String emailOrUsername,
    required String password,
  });

  Future<void> register({
    required String email,
    required String password,
    required String username,
    String? phone,
    required String targetCountry,
  });

  Future<void> logout();
}
