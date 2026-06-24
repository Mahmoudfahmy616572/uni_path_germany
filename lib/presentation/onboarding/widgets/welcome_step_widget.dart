import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';

class WelcomeStepWidget extends StatelessWidget {
  const WelcomeStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CurtainDrop(
            index: 0,
            child: Container(
              height: 220.h,
              width: 220.r,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('🎓', style: TextStyle(fontSize: 80.sp)),
              ),
            ),
          ),
          SizedBox(height: 40.h),
          CurtainDrop(
            index: 1,
            child: Text(
              AppLocalizations.of(context).translate('welcomeTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: context.isDark ? AppColors.textMain : AppColors.textDark,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          CurtainDrop(
            index: 2,
            child: Text(
              AppLocalizations.of(context).translate('welcomeSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 16.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
