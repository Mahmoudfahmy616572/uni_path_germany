import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/errors/message_error_handler.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../widgets/custom_auth_field.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';

class RegisterScreen extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  RegisterScreen({super.key, this.profileData});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          CustomSnackBar.show(
            context,
            message: 'Account created successfully! Redirecting...',
            isError: false,
          );
          // التحويل يتم تلقائياً عبر GoRouter بفضل مراقبة authStateChanges
        } else if (state is RegisterError) {
          final friendlyMessage = AuthErrorHandler.getFriendlyErrorMessage(
            context,
            state.message,
          );
          CustomSnackBar.show(context, message: friendlyMessage, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textDark,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Account 🚀",
                style: GoogleFonts.poppins(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Join UniPath to achieve your dreams in Germany.",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 30.h),

              Row(
                children: [
                  Expanded(
                    child: CustomAuthField(
                      hint: "Username",
                      prefixIcon: Icons.person_outline,
                      controller: _usernameController,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: CustomAuthField(
                      hint: "Phone",
                      prefixIcon: Icons.phone_outlined,
                      controller: _phoneController,
                    ),
                  ),
                ],
              ),

              CustomAuthField(
                hint: "Email address",
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
              ),
              CustomAuthField(
                hint: "Password",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              CustomAuthField(
                hint: "Confirm password",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _confirmPasswordController,
              ),

              SizedBox(height: 24.h),

              BlocBuilder<RegisterCubit, RegisterState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: state is RegisterLoading
                          ? null
                          : () => _onRegisterPressed(context),
                      child: state is RegisterLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  void _onRegisterPressed(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_emailRegex.hasMatch(email)) {
      CustomSnackBar.show(
        context,
        message: 'Please enter a valid email address.',
        isError: true,
      );
      return;
    }

    if (password != confirmPassword) {
      CustomSnackBar.show(
        context,
        message: 'Passwords do not match.',
        isError: true,
      );
      return;
    }

    // 🎯 تمرير كافة البيانات المستلمة من الـ Onboarding للكيوبيت
    context.read<RegisterCubit>().registerUser(
      email: email,
      password: password,
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
      gpa: profileData?['gpa'],
      maxGpa: profileData?['maxGpa'],
      minGpa: profileData?['minGpa'],
      hasMoi: profileData?['hasMoi'],
      hasIelts: profileData?['hasIelts'],
      ieltsScore: profileData?['ieltsScore'],
      targetMajor: profileData?['targetMajor'],
      intake: profileData?['intake'] ?? 'Both Semesters',
      languagePreference:
          profileData?['languagePreference'] ?? 'English', // 🎯 الحقل الجديد
    );
  }
}
