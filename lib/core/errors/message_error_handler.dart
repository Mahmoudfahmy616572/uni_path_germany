import 'package:flutter/material.dart';

class AuthErrorHandler {
  static String getFriendlyErrorMessage(
    BuildContext context,
    String supabaseError,
  ) {
    final String currentLang = Localizations.localeOf(context).languageCode;
    final bool isArabic = currentLang == 'ar';
    final error = supabaseError.toLowerCase();

    // DEBUG LOG
    print('🔴 AuthErrorHandler received: $error');

    // 0. Email confirmation required
    if (error.contains('email_confirm') ||
        error.contains('email_not_confirmed') ||
        error.contains('confirm your email') ||
        error.contains('email_confirmation_required') ||
        error.contains('email_not_verified')) {
      return isArabic
          ? 'يرجى تأكيد بريدك الإلكتروني أولاً. تحقق من صندوق الوارد.'
          : 'Please confirm your email first. Check your inbox.';
    }

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
        error.contains('user already exists') ||
        error.contains('email already')) {
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
        error.contains('password is too weak') ||
        error.contains('password_too_short') ||
        error.contains('password should be at least')) {
      return isArabic
          ? 'كلمة المرور ضعيفة، يرجى إدخال كلمة مرور أكثر تعقيداً.'
          : 'Password is too weak. Please enter a more complex password.';
    }

    // 5. أخطاء شبكة الاتصال
    if (error.contains('network') ||
        error.contains('socket') ||
        error.contains('connection failed') ||
        error.contains('timeout') ||
        error.contains('dns')) {
      return isArabic
          ? 'فشل الاتصال بالخادم، يرجى التحقق من الإنترنت.'
          : 'Network connection failed. Please check your internet.';
    }

    // 6. Invalid credentials
    if (error.contains('invalid login credentials') ||
        error.contains('invalid credentials') ||
        error.contains('wrong password') ||
        error.contains('invalid email or password')) {
      return isArabic
          ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
          : 'Incorrect email or password.';
    }

    // 7. User not found
    if (error.contains('user not found') ||
        error.contains('no user') ||
        error.contains('not found')) {
      return isArabic
          ? 'لا يوجد حساب بهذا البريد الإلكتروني.'
          : 'No account found with this email.';
    }

    // 8. RLS / Policy errors
    if (error.contains('row level security') ||
        error.contains('permission denied') ||
        error.contains('policy') ||
        error.contains('rls')) {
      return isArabic
          ? 'خطأ في إعدادات الخادم. يرجى التواصل مع الدعم.'
          : 'Server configuration error. Please contact support.';
    }

    // 9. Signup disabled
    if (error.contains('signup_disabled') ||
        error.contains('registration disabled')) {
      return isArabic
          ? 'التسجيل معطل حالياً. تواصل مع الدعم.'
          : 'Registration is currently disabled. Contact support.';
    }

    // Include actual error for debugging
    return isArabic
        ? 'فشل العملية: $supabaseError'
        : 'Operation failed: $supabaseError';
  }
}
