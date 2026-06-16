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
import '../../../../core/themes/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../../core/widgets/curtain_drop.dart';
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

  // 1. ØªØ¹Ø±ÙŠÙ Ø§Ù„Ù…ÙØªØ§Ø­ Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ù€ Form Ù„Ø¹Ù…Ù„ Ø§Ù„Ù€ Validation
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
          if (!context.mounted) return;
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
        backgroundColor: context.isDark ? AppColors.darkBackground : AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              CurtainDrop(
                index: 0,
                child: SizedBox(
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
                          color: context.isDark ? AppColors.darkCardBg : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
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
              ),
              CurtainDrop(
                index: 1,
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Form(
                    key: _formKey, // 2. Ø±Ø¨Ø· Ø§Ù„Ù€ Form Ø¨Ø§Ù„Ù…ÙØªØ§Ø­
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        AppLocalizations.of(context).translate('welcomeBack'),
                        style: GoogleFonts.poppins(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: context.isDark ? AppColors.textMain : AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        AppLocalizations.of(context).translate('loginSubtitle'),
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: context.isDark ? AppColors.textMuted : AppColors.textGrey,
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // 3. Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù€ validator Ù„Ø­Ù‚Ù„ Ø§Ù„Ø¥ÙŠÙ…ÙŠÙ„/Ø§Ù„ÙŠÙˆØ²Ø± Ù†ÙŠÙ…
                      CustomAuthField(
                        hint: AppLocalizations.of(context).translate('emailOrUsername'),
                        prefixIcon: Icons.email_outlined,
                        controller: _emailOrUsernameController,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context).translate('enterEmailOrUsername');
                          }
                          return null;
                        },
                      ),

                      // 4. Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù€ validator Ù„Ø­Ù‚Ù„ Ø§Ù„Ø¨Ø§Ø³ÙˆØ±Ø¯ ÙˆØªØ´Ø±ÙŠØ¹ Ø§Ù„Ù€ 6 Ø­Ø±ÙˆÙ
                      CustomAuthField(
                        hint: AppLocalizations.of(context).translate('password'),
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context).translate('enterPassword');
                          }
                          if (value.length < 6) {
                            return AppLocalizations.of(context).translate('passwordMinLength');
                          }
                          return null;
                        },
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            AppLocalizations.of(context).translate('forgotPassword'),
                            style: TextStyle(color: context.isDark ? AppColors.primaryPurple : AppColors.primary),
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
                            activeColor: context.isDark ? AppColors.primaryPurple : AppColors.primary,
                          ),
                          Text(
                            AppLocalizations.of(context).translate('rememberMe'),
                            style: TextStyle(
                              color: context.isDark ? AppColors.textMuted : AppColors.textGrey,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      BlocBuilder<LoginCubit, LoginState>(
                        builder: (context, state) {
                          return LoadingButton(
                            text: AppLocalizations.of(context).translate('login'),
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
                                AppLocalizations.of(context).translate('or'),
                                style: TextStyle(color: context.isDark ? AppColors.textMuted : AppColors.textGrey),
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
                          Text(
                            AppLocalizations.of(context).translate('noAccount'),
                            style: TextStyle(color: context.isDark ? AppColors.textMuted : AppColors.textGrey),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push('/register');
                            },
                            child: Text(
                              AppLocalizations.of(context).translate('register'),
                              style: TextStyle(
                                color: context.isDark ? AppColors.primaryPurple : AppColors.primary,
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
            ),
          ],
        ),
        ),
      ),
    );
  }
}
