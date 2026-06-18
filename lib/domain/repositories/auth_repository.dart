import 'package:supabase_flutter/supabase_flutter.dart';

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

  // 🎯 تسجيل الدخول عبر OAuth (Google, Apple, Facebook)
  Future<void> signInWithOAuth(OAuthProvider provider);

  // 🎯 إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email);
}
