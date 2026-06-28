import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/message_error_handler.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/auth_illustrations.dart';
import '../../../../core/widgets/curtain_drop.dart';
import '../../login/cubit/login_cubit.dart';
import '../../login/cubit/login_state.dart';
import '../../widgets/custom_auth_field.dart';
import '../../widgets/loading_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginPasswordResetSent) {
          context.pop();
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
                  child: ForgotPasswordIllustration(),
                ),
              ),
              CurtainDrop(
                index: 1,
                child: Text(
                  AppLocalizations.of(context).translate('forgotPassword'),
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
                    AppLocalizations.of(context).translate('forgotPasswordSubtitle'),
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
                        hint: AppLocalizations.of(context).translate('email'),
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context).translate('enterEmailAddress');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),
                      BlocBuilder<LoginCubit, LoginState>(
                        builder: (context, state) {
                          return LoadingButton(
                            text: AppLocalizations.of(context).translate('sendResetLink'),
                            isLoading: state is LoginLoading,
                            onPressed: state is LoginLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<LoginCubit>().resetPassword(
                                        _emailController.text.trim(),
                                      );
                                    }
                                  },
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('rememberYourPassword'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFAAB1C5) : const Color(0xFF64748B),
                        fontSize: 14.sp,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        AppLocalizations.of(context).translate('login'),
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
