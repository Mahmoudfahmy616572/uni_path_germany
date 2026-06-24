import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';

class ProfileToolItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ProfileToolItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6.r,
            offset: Offset(0, 3.r),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: context.isDark ? AppColors.textMuted : Colors.grey, fontSize: 12.sp),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: context.isDark ? AppColors.textMuted : Colors.grey,
        ),
        onTap: onTap,
      ),
      ),
    );
  }
}
