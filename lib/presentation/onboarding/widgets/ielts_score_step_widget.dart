import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class IeltsScoreStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const IeltsScoreStepWidget({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurtainDrop(
            index: 0,
            child: Text(
              AppLocalizations.of(context).translate('ieltsScoreHeading'),
              style: TextStyle(
                color: context.isDark ? AppColors.textMain : AppColors.textDark,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          CurtainDrop(
            index: 1,
            child: Text(
              AppLocalizations.of(context).translate('ieltsScoreSubtitle'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          const Spacer(),
          CurtainDrop(
            index: 2,
            child: Center(
              child: Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: Center(
                  child: Text(
                    state.ieltsScore.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          CurtainDrop(
            index: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: context.inputBgColor,
                trackHeight: 8.h,
                thumbColor: AppColors.primary,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                valueIndicatorColor: AppColors.primary,
                valueIndicatorTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              child: Slider(
                value: state.ieltsScore >= 4.0
                    ? state.ieltsScore
                    : 6.0,
                min: 4.0,
                max: 9.0,
                divisions: 10,
                label: state.ieltsScore.toStringAsFixed(1),
                onChanged: (value) => cubit.updateIeltsScore(value),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '4.0',
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '6.5',
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '9.0',
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
