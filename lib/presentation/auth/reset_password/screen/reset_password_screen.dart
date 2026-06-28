import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/auth_illustrations.dart';
import '../../../../core/widgets/curtain_drop.dart';
import '../../widgets/loading_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? code;
  const ResetPasswordScreen({super.key, this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onResetPressed() {
    if (_formKey.currentState!.validate()) {
      CustomSnackBar.show(
        context,
        message: AppLocalizations.of(context).translate('passwordResetSuccess'),
        isError: false,
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: Column(
          children: [
            SizedBox(height: 40.h),
            CurtainDrop(
              index: 0,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40.h),
                  child: ResetPasswordIllustration(),
              ),
            ),
            CurtainDrop(
              index: 1,
              child: Text(
                AppLocalizations.of(context).translate('resetPassword'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            CurtainDrop(
              index: 2,
              child: Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Text(
                  AppLocalizations.of(context).translate('resetPasswordSubtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? const Color(0xFFAAB1C5) : const Color(0xFF64748B),
                    height: 1.7,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
            CurtainDrop(
              index: 3,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      height: 58.h,
                      margin: EdgeInsets.only(bottom: 18.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151C2F) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16.r),
                        border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 15.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).translate('newPassword'),
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return AppLocalizations.of(context).translate('enterPasswordRegister');
                          if (value.length < 6) return AppLocalizations.of(context).translate('passwordMinLength');
                          return null;
                        },
                      ),
                    ),
                    Container(
                      height: 58.h,
                      margin: EdgeInsets.only(bottom: 18.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151C2F) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16.r),
                        border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 15.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).translate('confirmPassword'),
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return AppLocalizations.of(context).translate('confirmYourPassword');
                          if (value != _passwordController.text) return AppLocalizations.of(context).translate('passwordsNotMatch');
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 20.h),
                      child: Text(
                        AppLocalizations.of(context).translate('passwordRequirements'),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.8,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    LoadingButton(
                      text: AppLocalizations.of(context).translate('resetPassword'),
                      onPressed: _onResetPressed,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
