import 'package:flutter/material.dart';

class AuthErrorHandler {
  static String getFriendlyErrorMessage(
    BuildContext context,
    String supabaseError,
  ) {
    final String currentLang = Localizations.localeOf(context).languageCode;
    final bool isArabic = currentLang == 'ar';
    final error = supabaseError.toLowerCase();

    // 1. أخطاء الـ Username
    if (error.contains('username_exists') ||
        error.contains('profiles_username_key') ||
        error.contains('duplicate key value violates unique constraint')) {
      if (error.contains('username')) {
        return isArabic
            ? 'اسم المستخدم هذا مأخوذ بالفعل، يرجى اختيار اسم آخر.'
            : 'This username is already taken, please choose another.';
      }
    }

    // 2. أخطاء الـ Email
    if (error.contains('already registered') ||
        error.contains('email_exists') ||
        error.contains('user already exists')) {
      return isArabic
          ? 'هذا البريد الإلكتروني مسجل لدينا بالفعل، يمكنك تسجيل الدخول به.'
          : 'This email is already registered. Try logging in instead.';
    }

    // 3. خطأ كثرة المحاولات
    if (error.contains('rate limit') || error.contains('too many requests')) {
      return isArabic
          ? 'لقد قمت بمحاولات كثيرة جداً، يرجى الانتظار دقيقة ثم المحاولة ثانية.'
          : 'Too many requests. Please wait a moment and try again.';
    }

    // 4. خطأ ضعف كلمة المرور
    if (error.contains('weak password') ||
        error.contains('password is too weak')) {
      return isArabic
          ? 'كلمة المرور ضعيفة، يرجى إدخال كلمة مرور أكثر تعقيداً.'
          : 'Password is too weak. Please enter a more complex password.';
    }

    // 5. أخطاء شبكة الاتصال
    if (error.contains('network') ||
        error.contains('socket') ||
        error.contains('connection failed')) {
      return isArabic
          ? 'فشل الاتصال بالخادم، يرجى التحقق من الإنترنت.'
          : 'Network connection failed. Please check your internet.';
    }

    // الرسالة الافتراضية
    return isArabic
        ? 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.'
        : 'An unexpected error occurred. Please try again later.';
  }
}
