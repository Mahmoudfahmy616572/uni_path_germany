import '../entities/user_entity.dart';

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
  });

  Future<void> logout();

  // 🎯 جلب بيانات المستخدم الحالي كاملة ككيان (Entity)
  Future<UserEntity?> getCurrentUser();

  // 🎯 تحديث بيانات البروفايل (Settings)
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  });

  // 🎯 حذف الحساب بالكامل
  Future<void> deleteAccount();
}
