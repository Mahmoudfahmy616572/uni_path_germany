import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';

class CustomAuthField extends StatefulWidget {
  final String hint;
  final IconData prefixIcon;

  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool autofocus;

  const CustomAuthField({
    super.key,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.autofocus = false,
  });

  @override
  State<CustomAuthField> createState() => _CustomAuthFieldState();
}

class _CustomAuthFieldState extends State<CustomAuthField> {
  bool _obscureText = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.autofocus) {
      // Delay focus request until after first frame to avoid conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword ? _obscureText : false,
        validator: widget.validator,
        decoration: InputDecoration(
          filled: false,
          hintText: widget.hint,
          hintStyle: TextStyle(color: context.isDark ? AppColors.textMuted : AppColors.textGrey, fontSize: 14.sp),
          prefixIcon: Icon(widget.prefixIcon, color: context.isDark ? AppColors.textMuted : AppColors.textGrey, size: 20),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: context.isDark ? AppColors.textMuted : AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
