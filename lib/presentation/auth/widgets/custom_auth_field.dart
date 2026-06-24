import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final isDark = context.isDark;

    return Container(
      height: 58.h,
      margin: EdgeInsets.only(bottom: 18.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C2F) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword ? _obscureText : false,
        validator: widget.validator,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 15.sp,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            widget.prefixIcon,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            size: 20,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
          contentPadding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
    );
  }
}
