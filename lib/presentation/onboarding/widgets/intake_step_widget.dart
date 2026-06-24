import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class IntakeStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const IntakeStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final intakes = [
      {
        'name': 'Winter Semester',
        'desc': 'Starts Sept/Oct (Main intake)',
        'icon': Icons.ac_unit,
      },
      {
        'name': 'Summer Semester',
        'desc': 'Starts March/April',
        'icon': Icons.wb_sunny,
      },
      {
        'name': 'Both Semesters',
        'desc': 'Flexible / Show all opportunities',
        'icon': Icons.all_inclusive,
      },
    ];

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurtainDrop(
            index: 0,
            child: Text(
              AppLocalizations.of(context).translate('intakeHeading'),
              style: TextStyle(
                color: context.isDark ? AppColors.textMain : AppColors.textDark,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          ...intakes.asMap().entries.map((entry) {
            final i = entry.key;
            final intake = entry.value;
            final isSelected = state.targetIntake == intake['name'];
            return CurtainDrop(
              index: i + 1,
              child: GestureDetector(
                onTap: () => cubit.updateIntake(intake['name'] as String),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  padding: EdgeInsets.all(18.r),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : context.inputBgColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        intake['icon'] as IconData,
                        color: isSelected
                            ? AppColors.primary
                            : context.textMutedColor,
                        size: 26,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              intake['name'] as String,
                              style: TextStyle(
                                color: context.isDark ? AppColors.textMain : AppColors.textDark,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              intake['desc'] as String,
                              style: TextStyle(
                                color: context.textMutedColor,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
