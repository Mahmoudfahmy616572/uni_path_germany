import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/themes/app_colors.dart';
import '../../widgets/custom_auth_field.dart';
import '../../widgets/social_auth_button.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  // الـ Controllers لكل الحقول الموجودة في الصورة
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, RegisterState>(
      // التعامل مع النتيجة (Success / Error)
      listener: (context, state) {
        if (state is RegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account Created! Please Login'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // العودة للـ Login
        } else if (state is RegisterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join thousands of students achieving their study abroad dreams",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 30),

              // صف الاسم ورقم التليفون
              Row(
                children: [
                  Expanded(
                    child: CustomAuthField(
                      hint: "Full name",
                      prefixIcon: Icons.person_outline,
                      controller: _nameController,
                    ),
                  ),
                  const SizedBox(width: 16),
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

              const SizedBox(height: 15),

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

              const SizedBox(height: 24),

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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: state is RegisterLoading
                          ? null
                          : () {
                              context.read<RegisterCubit>().register(
                                email: _emailController.text,
                                password: _passwordController.text,
                                name: _nameController.text,
                                phone: _phoneController
                                    .text, // مرره لو الـ Cubit بيستقبله
                                // phone: _phoneController.text, // مرره لو الـ Cubit بيستقبله
                              );
                              print(
                                "Register button pressed with email: ${_emailController.text}",
                              );
                              print(
                                "Register button pressed with password: ${_passwordController.text}",
                              );
                              print(
                                "Register button pressed with name: ${_nameController.text}",
                              );
                              print(
                                "Register button pressed with phone: ${_phoneController.text}",
                              );
                              print("Register button pressed ");
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
                          : const Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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

              const SizedBox(height: 20),
              // الـ Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
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
              const SizedBox(height: 30),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("or", style: TextStyle(color: AppColors.textGrey)),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}
