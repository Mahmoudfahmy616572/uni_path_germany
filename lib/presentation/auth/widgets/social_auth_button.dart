import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/themes/app_theme.dart';

class SocialAuthButton extends StatelessWidget {
  final String text;
  final FaIconData icon;
  final Color iconColor;
  final VoidCallback? onPressed;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.icon,
    required this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF151C2F) : Colors.white,
          side: BorderSide(
            color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        onPressed: onPressed,
        icon: FaIcon(icon, color: iconColor, size: 20.sp),
        label: Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
            fontSize: 15.sp,
          ),
        ),
      ),
    );
  }
}
