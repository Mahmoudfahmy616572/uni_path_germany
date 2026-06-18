import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/themes/app_colors.dart';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: context.isDark ? AppColors.darkCardBg : Colors.white,
          side: BorderSide(color: context.isDark ? AppColors.darkBorder : Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: onPressed,
        icon: FaIcon(icon, color: iconColor),
        label: Text(
          text,
          style: TextStyle(
            color: context.isDark ? AppColors.textMain : AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
