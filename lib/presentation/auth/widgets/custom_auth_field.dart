import 'package:flutter/material.dart';
import 'package:germany_travel/core/themes/app_colors.dart';

class CustomAuthField extends StatelessWidget {
  final String hint;
  final IconData prefixIcon;

  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CustomAuthField({
    super.key,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: AppColors.textGrey, size: 20),
          suffixIcon: isPassword
              ? const Icon(
                  Icons.remove_red_eye_outlined,
                  color: AppColors.textGrey,
                  size: 20,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
