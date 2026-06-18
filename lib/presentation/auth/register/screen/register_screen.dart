import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/curtain_drop.dart';
import '../../../../core/errors/message_error_handler.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/curtain_drop.dart';
import '../../widgets/custom_auth_field.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/social_auth_button.dart';
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
    log.i('REGISTER SCREEN BUILD');
    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) async {
        log.i('REGISTER LISTENER: ${state.runtimeType}');
        if (state is RegisterSuccess) {
          log.i('REGISTER SUCCESS - going to /home');
          CustomSnackBar.show(
            context,
            message: AppLocalizations.of(context).translate('registerSuccess'),
            isError: false,
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (_emailController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty) {
            await LocalStorageService.saveCredentials(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              rememberMe: true,
            );
          }
          if (!context.mounted) return;
          context.go('/home');
        } else if (state is RegisterError) {
          final friendlyMessage = AuthErrorHandler.getFriendlyErrorMessage(
            context,
            state.message,
          );
          CustomSnackBar.show(context, message: friendlyMessage, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: context.isDark ? AppColors.textMain : AppColors.textDark,
                size: 20,
              ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AuthBackground(
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurtainDrop(
                  index: 0,
                  child: Text(
                    AppLocalizations.of(context).translate('createAccount'),
                    style: GoogleFonts.poppins(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: context.isDark ? AppColors.textMain : AppColors.textDark,
                    ),
                  ),
                ),
                CurtainDrop(
                  index: 1,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      AppLocalizations.of(context).translate('registerSubtitle'),
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: context.isDark ? AppColors.textMuted : AppColors.textGrey,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),

                CurtainDrop(
                  index: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomAuthField(
                          hint: AppLocalizations.of(context).translate('username'),
                          prefixIcon: Icons.person_outline,
                          controller: _usernameController,
                          autofocus: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context).translate('enterUsername');
                            }
                            if (value.trim().length < 3) {
                              return AppLocalizations.of(context).translate('usernameMinLength');
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: CustomAuthField(
                          hint: AppLocalizations.of(context).translate('phoneOptional'),
                          prefixIcon: Icons.phone_outlined,
                          controller: _phoneController,
                        ),
                      ),
                    ],
                  ),
                ),
                CurtainDrop(
                  index: 3,
                  child: CustomAuthField(
                    hint: AppLocalizations.of(context).translate('email'),
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context).translate('enterEmailAddress');
                      }
                      if (!_emailRegex.hasMatch(value.trim())) {
                        return AppLocalizations.of(context).translate('enterValidEmail');
                      }
                      return null;
                    },
                  ),
                ),
                CurtainDrop(
                  index: 4,
                  child: CustomAuthField(
                    hint: AppLocalizations.of(context).translate('password'),
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context).translate('enterPasswordRegister');
                      }
                      if (value.length < 6) {
                        return AppLocalizations.of(context).translate('passwordMinLengthRegister');
                      }
                      return null;
                    },
                  ),
                ),
                CurtainDrop(
                  index: 5,
                  child: CustomAuthField(
                    hint: AppLocalizations.of(context).translate('confirmPassword'),
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context).translate('confirmYourPassword');
                      }
                      if (value != _passwordController.text) {
                        return AppLocalizations.of(context).translate('passwordsNotMatch');
                      }
                      return null;
                    },
                  ),
                ),

                SizedBox(height: 24.h),
                CurtainDrop(
                  index: 6,
                  child: BlocBuilder<RegisterCubit, RegisterState>(
                  builder: (context, state) {
                    return LoadingButton(
                      text: AppLocalizations.of(context).translate('createAccount'),
                      isLoading: state is RegisterLoading,
                      onPressed: state is RegisterLoading
                          ? null
                          : () => _onRegisterPressed(context),
                    );
                  },
                ),
                ),
                SizedBox(height: 24.h),
                CurtainDrop(
                  index: 7,
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
                SizedBox(height: 16.h),
                CurtainDrop(
                  index: 8,
                  child: Column(
                    children: [
                      SocialAuthButton(
                        text: "Continue with Google",
                        icon: FontAwesomeIcons.google,
                        iconColor: Colors.red,
                        onPressed: () => context.read<RegisterCubit>().signInWithOAuth(
                          OAuthProvider.google,
                          profileData: profileData,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                CurtainDrop(
                  index: 9,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('alreadyHaveAccount'),
                        style: TextStyle(color: context.isDark ? AppColors.textMuted : AppColors.textGrey),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push('/login');
                        },
                        child: Text(
                          AppLocalizations.of(context).translate('login'),
                          style: TextStyle(
                            color: context.isDark ? AppColors.primaryPurple : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
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
        academicAverage: profileData?['academicAverage'],
        highSchoolScore: profileData?['highSchoolScore'],
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
