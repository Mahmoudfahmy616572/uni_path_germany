import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:germany_travel/presentation/auth/login/cubit/login_cubit.dart';
import 'package:germany_travel/presentation/auth/login/cubit/login_state.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/errors/message_error_handler.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/services/services_locator.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../widgets/custom_auth_field.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/social_auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailOrUsernameController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 1. تعريف المفتاح الخاص بالـ Form لعمل الـ Validation
  final _formKey = GlobalKey<FormState>();

  // Remember me
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final creds = LocalStorageService.getCredentials();
    if (creds != null && creds.rememberMe) {
      setState(() {
        _rememberMe = true;
        _emailOrUsernameController.text = creds.email;
        _passwordController.text = creds.password;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await LocalStorageService.saveCredentials(
        email: _emailOrUsernameController.text.trim(),
        password: _passwordController.text,
        rememberMe: true,
      );
    } else {
      await LocalStorageService.clearCredentials();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) async {
        if (state is LoginSuccess) {
          await LocalStorageService.saveCredentials(
            email: _emailOrUsernameController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );

          final authService = sl<AuthService>();
          final profileComplete = await authService.isProfileComplete();
          if (profileComplete) {
            context.go('/home');
          } else {
            context.go('/onboarding');
          }
        } else if (state is LoginError) {
          final friendlyMessage = AuthErrorHandler.getFriendlyErrorMessage(
            context,
            state.message,
          );

          CustomSnackBar.show(context, message: friendlyMessage, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Image & Logo
              SizedBox(
                height: 280,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 250,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "TUM",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 24.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(24.r),
                child: Form(
                  key: _formKey, // 2. ربط الـ Form بالمفتاح
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back! 👋",
                        style: GoogleFonts.poppins(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Login to continue your study abroad journey",
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // 3. إضافة الـ validator لحقل الإيميل/اليوزر نيم
                      CustomAuthField(
                        hint: "Email address or Username",
                        prefixIcon: Icons.email_outlined,
                        controller: _emailOrUsernameController,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email or username';
                          }
                          return null;
                        },
                      ),

                      // 4. إضافة الـ validator لحقل الباسورد وتشريع الـ 6 حروف
                      CustomAuthField(
                        hint: "Password",
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // Remember me checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                            activeColor: AppColors.primary,
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      BlocBuilder<LoginCubit, LoginState>(
                        builder: (context, state) {
                          return LoadingButton(
                            text: "Login",
                            isLoading: state is LoginLoading,
                            onPressed: state is LoginLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      await _saveCredentials();
                                      context.read<LoginCubit>().login(
                                        emailOrUsername: _emailOrUsernameController.text
                                            .trim(),
                                        password: _passwordController.text,
                                      );
                                    }
                                  },
                          );
                        },
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.r),
                              child: Text(
                                "or",
                                style: TextStyle(color: AppColors.textGrey),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),

                      const SocialAuthButton(
                        text: "Continue with Google",
                        icon: FontAwesomeIcons.google,
                        iconColor: Colors.red,
                      ),
                      const SocialAuthButton(
                        text: "Continue with Apple",
                        icon: FontAwesomeIcons.apple,
                        iconColor: Colors.black,
                      ),
                      const SocialAuthButton(
                        text: "Continue with Facebook",
                        icon: FontAwesomeIcons.facebook,
                        iconColor: Colors.blue,
                      ),

                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppColors.textGrey),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push('/register');
                            },
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
