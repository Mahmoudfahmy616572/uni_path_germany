import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/errors/message_error_handler.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../widgets/custom_auth_field.dart';
import '../../widgets/social_auth_button.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';

class RegisterScreen extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  // 🎯 حدّث الـ Constructor عشان ياخد الـ Parameter ده
  RegisterScreen({super.key, this.profileData});

  // الـ Controllers لكل الحقول الموجودة في الصورة
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,16}$');
  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, RegisterState>(
      // التعامل مع النتيجة (Success / Error)
      listener: (context, state) {
        if (state is RegisterSuccess) {
          final String currentLang = Localizations.localeOf(
            context,
          ).languageCode;

          CustomSnackBar.show(
            context,
            message: currentLang == 'ar'
                ? 'تم إنشاء الحساب بنجاح! يرجى التحقق من بريدك لتأكيده.'
                : 'Account created successfully! Please verify your email.',
            isError: false, // هيظهر باللون الأخضر الشيك
          );

          // الانتقال لشاشة تسجيل الدخول أو الشاشة الرئيسية
          context.go('/login');
        } else if (state is RegisterError) {
          print("Supabase Original Error: ${state.message}");
          // تمرير الـ context لمعرفة اللغة + رسالة الإيرور الخام القادمة من الكيوبيت
          final friendlyMessage = AuthErrorHandler.getFriendlyErrorMessage(
            context,
            state.message,
          );

          // إظهار السناك بار المخصصة الاحترافية
          CustomSnackBar.show(
            context,
            message: AuthErrorHandler.getFriendlyErrorMessage(
              context,
              state.message,
            ),
            isError: true, // هيظهر باللون الأحمر
          );
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
              // العنوان والوصف كما في الصورة تماماً
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
                "Join thousands of students achieving their study abroad dreams",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 30.h),

              // صف الاسم ورقم التليفون
              Row(
                children: [
                  Expanded(
                    child: CustomAuthField(
                      hint: "Full name",
                      prefixIcon: Icons.person_outline,
                      controller: _usernameController,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: CustomAuthField(
                      hint: "Phone number",
                      prefixIcon: Icons.phone_outlined,
                      controller: _phoneController,
                    ),
                  ),
                ],
              ),

              // باقي الحقول
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

              SizedBox(height: 15.h),

              // الـ 3 كروت التعريفية (Info Cards) بنفس التصميم
              _buildInfoCard(
                Icons.verified_user_outlined,
                "Secure & Private",
                "Your data is protected with enterprise grade security",
                Colors.blue.shade700,
              ),
              _buildInfoCard(
                Icons.rocket_launch_outlined,
                "Personalized Experience",
                "Get AI-powered recommendations tailored to your goals",
                Colors.purple.shade700,
              ),
              _buildInfoCard(
                Icons.school_outlined,
                "Achieve Your Goals",
                "Join thousands of students successfully studying abroad",
                Colors.indigo.shade700,
              ),

              SizedBox(height: 24.h),

              // زرار الإنشاء مع الـ Loading Logic
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
                        elevation: 0,
                      ),
                      onPressed: state is RegisterLoading
                          ? null
                          : () {
                              print("🎯 PROFILE DATA IN SCREEN: $profileData");
                              final username = _usernameController.text.trim();
                              final password = _passwordController.text.trim();
                              final email = _emailController.text.trim();
                              final confirmPassword = _confirmPasswordController
                                  .text
                                  .trim();
                              final String currentLang = Localizations.localeOf(
                                context,
                              ).languageCode;
                              final bool isArabic = currentLang == 'ar';
                              if (!_emailRegex.hasMatch(email)) {
                                CustomSnackBar.show(
                                  context,
                                  message:
                                      'Please enter a valid email address.',
                                  isError: true,
                                );
                                return;
                              }
                              if (!_usernameRegex.hasMatch(username)) {
                                CustomSnackBar.show(
                                  context,
                                  message:
                                      'Please enter a valid username (3-16 characters, alphanumeric and underscores only).',
                                  isError: true,
                                );
                                return;
                              }
                              if (password != confirmPassword) {
                                // إظهار سناك بار مخصصة فوراً إنهم مش متطابقين بدون إرهاق السيرفر
                                CustomSnackBar.show(
                                  context,
                                  message: isArabic
                                      ? 'كلمتا المرور غير متطابقتين، يرجى التحقق.'
                                      : 'Passwords do not match. Please check.',
                                  isError: true,
                                );
                                return; // وقف العملية هنا ومتخليهوش يروح للـ Cubit
                              }
                              context.read<RegisterCubit>().registerUser(
                                email: _emailController.text,
                                password: _passwordController.text,
                                username: _usernameController.text,
                                phone: null, // أو الـ controller بتاعه لو موجود
                                // 🔥 التصحيح الملي متري هنا:
                                gpa: profileData?['gpa'],
                                // 🔥 الحقول الجديدة المضافة للـ Matching وتعديل الـ حسابات:
                                maxGpa:
                                    profileData?['maxGpa'] ??
                                    4.0, // 👈 سحب الـ maxGpa مع قيمة افتراضية لأمان الـ UI
                                minGpa:
                                    profileData?['minGpa'] ??
                                    1.0, // 👈 سحب الـ minGpa مع قيمة افتراضية لأمان الـ UI
                                hasMoi: profileData?['hasMoi'] ?? false,
                                targetMajor:
                                    profileData?['targetMajor'], // 👈 رجعها camelCase لأنها مطبوعة كدة في الـ Console
                                hasIelts:
                                    profileData?['hasIelts'] ??
                                    false, // 👈 رجعها camelCase
                                ieltsScore: profileData?['ieltsScore'],
                                targetCountry: profileData?['targetCountry'], //
                              );
                            },
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

              // الـ Divider والـ Social Buttons
              _buildDivider(),
              const SocialAuthButton(
                text: "Sign up with Google",
                icon: FontAwesomeIcons.google,
                iconColor: Colors.red,
              ),
              const SocialAuthButton(
                text: "Sign up with Apple",
                icon: FontAwesomeIcons.apple,
                iconColor: Colors.black,
              ),

              SizedBox(height: 20.h),
              // الـ Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: () {
                      // 🎯 بدل pop()، هنخليه يروح لصفحة الـ login بشكل صريح ومباشر
                      context.go('/login');
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
    );
  }

  // ويدجيت الكروت (نفس استايل الصورة)
  Widget _buildInfoCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.r),
            child: Text("or", style: TextStyle(color: AppColors.textGrey)),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}
