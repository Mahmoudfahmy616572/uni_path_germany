import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/errors/message_error_handler.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../widgets/custom_auth_field.dart';
import '../../widgets/loading_button.dart';
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

  // 1. تعريف المفتاح الخاص بالـ Form لعمل الـ Validation
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    print('🔨 REGISTER SCREEN BUILD');
    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) async {
        print('🔄 REGISTER LISTENER: ${state.runtimeType}');
        if (state is RegisterSuccess) {
          print('✅ REGISTER SUCCESS - going to /onboarding');
          await LocalStorageService.saveCredentials(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberMe: true,
          );
          // Navigate to onboarding to complete profile
          context.go('/onboarding');
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
          child: Form(
            key: _formKey,
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
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomAuthField(
                        hint: "Phone (optional)",
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!_emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                CustomAuthField(
                  hint: "Password",
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                CustomAuthField(
                  hint: "Confirm password",
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  controller: _confirmPasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                BlocBuilder<RegisterCubit, RegisterState>(
                  builder: (context, state) {
                    return LoadingButton(
                      text: "Create Account",
                      isLoading: state is RegisterLoading,
                      onPressed: state is RegisterLoading
                          ? null
                          : () => _onRegisterPressed(context),
                    );
                  },
                ),
                SizedBox(height: 24.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.push('/login');
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onRegisterPressed(BuildContext context) {
    // 5. التحقق من صحة النموذج قبل مناداة الكيوبيت
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

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
        degreeLevel: profileData?['degreeLevel'], // 🎯 تمرير مستوى الدرجة
      );
    }
  }
}
