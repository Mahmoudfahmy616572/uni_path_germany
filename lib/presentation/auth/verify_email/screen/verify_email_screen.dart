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

class VerifyEmailScreen extends StatefulWidget {
  final String? email;
  const VerifyEmailScreen({super.key, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitInput(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onVerifyPressed() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 4) {
      CustomSnackBar.show(
        context,
        message: AppLocalizations.of(context).translate('emailVerifiedSuccess'),
        isError: false,
      );
      context.go('/home');
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
                  child: VerifyEmailIllustration(),
              ),
            ),
            CurtainDrop(
              index: 1,
              child: Text(
                AppLocalizations.of(context).translate('verifyEmail'),
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
                  AppLocalizations.of(context).translate('verificationCodeSent').replaceAll('{email}', widget.email ?? AppLocalizations.of(context).translate('email')),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? const Color(0xFFAAB1C5) : const Color(0xFF64748B),
                    height: 1.7,
                  ),
                ),
              ),
            ),
            SizedBox(height: 35.h),
            CurtainDrop(
              index: 3,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 70.w,
                          height: 70.h,
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              filled: true,
                              fillColor: isDark ? const Color(0xFF151C2F) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18.r),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18.r),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFF5B5EF7),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) => _onDigitInput(index, value),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "";
                              return null;
                            },
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 25.h),
                    Text(
                      AppLocalizations.of(context).translate('didntReceiveCode'),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${AppLocalizations.of(context).translate('resendIn')}00:45',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF7C4DFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 25.h),
                    LoadingButton(
                      text: AppLocalizations.of(context).translate('verifyCode'),
                      onPressed: _onVerifyPressed,
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
