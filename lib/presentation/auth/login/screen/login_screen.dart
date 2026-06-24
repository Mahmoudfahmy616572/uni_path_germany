import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:germany_travel/presentation/auth/login/cubit/login_cubit.dart';
import 'package:germany_travel/presentation/auth/login/cubit/login_state.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/message_error_handler.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/services_locator.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/auth_illustrations.dart';
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

  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _tryBiometricLogin();
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

  Future<void> _tryBiometricLogin() async {
    final enabled = await BiometricService.isBiometricEnabled();
    if (!enabled) return;
    final available = await BiometricService.isAvailable();
    if (!available) return;
    final authed = await BiometricService.authenticate();
    if (!authed) return;
    if (!mounted) return;
    final creds = LocalStorageService.getCredentials();
    if (creds != null) {
      _emailOrUsernameController.text = creds.email;
      _passwordController.text = creds.password;
      _onLogin();
    }
  }

  Future<void> _onLogin() async {
    if (_formKey.currentState!.validate()) {
      await _saveCredentials();
      context.read<LoginCubit>().login(
        emailOrUsername: _emailOrUsernameController.text.trim(),
        password: _passwordController.text,
      );
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
    final isDark = context.isDark;

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) async {
        if (state is LoginSuccess) {
          CustomSnackBar.show(
            context,
            message: AppLocalizations.of(context).translate('loginSuccess'),
            isError: false,
          );
          await Future.delayed(const Duration(milliseconds: 500));

          await LocalStorageService.saveCredentials(
            email: _emailOrUsernameController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );

          final authService = sl<AuthService>();
          final profileComplete = await authService.isProfileComplete();
          if (!context.mounted) return;
          if (profileComplete) {
            NotificationService.requestNotificationPermission();
            context.go('/home');
          } else {
            context.go('/onboarding');
          }
        } else if (state is LoginPasswordResetSent) {
          CustomSnackBar.show(
            context,
            message: AppLocalizations.of(context).translate('passwordResetSent'),
            isError: false,
          );
        } else if (state is LoginError) {
          final friendlyMessage = AuthErrorHandler.getFriendlyErrorMessage(
            context,
            state.message,
          );

          CustomSnackBar.show(context, message: friendlyMessage, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AuthBackground(
          child: Column(
            children: [
              SizedBox(height: 40.h),
              CurtainDrop(
                index: 0,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40.h),
                  child: LoginIllustration(),
                ),
              ),
              CurtainDrop(
                index: 1,
                child: Text(
                  AppLocalizations.of(context).translate('welcomeBack'),
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
                    AppLocalizations.of(context).translate('loginSubtitle'),
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
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                activeColor: const Color(0xFF7C4DFF),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(
                                AppLocalizations.of(context).translate('rememberMe'),
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFAAB1C5) : const Color(0xFF64748B),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: Text(
                              AppLocalizations.of(context).translate('forgotPassword'),
                              style: TextStyle(
                                color: const Color(0xFF7C4DFF),
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Biometric login option
                      if (_rememberMe) ...[
                        SizedBox(height: 8.h),
                        FutureBuilder<bool>(
                          future: BiometricService.isAvailable(),
                          builder: (context, snapshot) {
                            if (snapshot.data != true) return const SizedBox.shrink();
                            return FutureBuilder<bool>(
                              future: BiometricService.isBiometricEnabled(),
                              builder: (context, enabledSnapshot) {
                                return CheckboxListTile(
                                  value: enabledSnapshot.data ?? false,
                                  onChanged: (v) async {
                                    if (v == true) {
                                      final authed = await BiometricService.authenticate();
                                      if (authed) {
                                        await BiometricService.setBiometricEnabled(true);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Biometric login enabled')),
                                          );
                                        }
                                      }
                                    } else {
                                      await BiometricService.setBiometricEnabled(false);
                                    }
                                    if (context.mounted) setState(() {});
                                  },
                                  title: Text(
                                    'Enable fingerprint / face unlock',
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                );
                              },
                            );
                          },
                        ),
                      ],
                      SizedBox(height: 20.h),
                      BlocBuilder<LoginCubit, LoginState>(
                        builder: (context, state) {
                          return LoadingButton(
                            text: AppLocalizations.of(context).translate('login'),
                            isLoading: state is LoginLoading,
                            onPressed: state is LoginLoading
                                ? null
                                : _onLogin,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              CurtainDrop(
                index: 4,
                child: Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? const Color(0xFF7A8199) : const Color(0xFF94A3B8))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.r),
                      child: Text(
                        AppLocalizations.of(context).translate('or'),
                        style: TextStyle(color: isDark ? const Color(0xFF7A8199) : const Color(0xFF94A3B8)),
                      ),
                    ),
                    Expanded(child: Divider(color: isDark ? const Color(0xFF7A8199) : const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              CurtainDrop(
                index: 5,
                child: SocialAuthButton(
                  text: "Continue with Google",
                  icon: FontAwesomeIcons.google,
                  iconColor: Colors.red,
                  onPressed: () => context.read<LoginCubit>().signInWithOAuth(OAuthProvider.google),
                ),
              ),
              SizedBox(height: 20.h),
              CurtainDrop(
                index: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('noAccount'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFAAB1C5) : const Color(0xFF64748B),
                        fontSize: 14.sp,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        AppLocalizations.of(context).translate('register'),
                        style: TextStyle(
                          color: const Color(0xFF7C4DFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
