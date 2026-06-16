import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class GoalsStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const GoalsStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final goalsList = [
      {'title': 'Find Scholarships', 'icon': Icons.card_giftcard_rounded},
      {'title': 'Post-Study Work Visa', 'icon': Icons.work_outline_rounded},
      {'title': 'Permanent Residency (PR)', 'icon': Icons.explore_outlined},
      {'title': 'Cultural Exchange & Travel', 'icon': Icons.public_rounded},
      {'title': 'High-Quality Research', 'icon': Icons.biotech_rounded},
    ];

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurtainDrop(
            index: 0,
            child: Text(
              AppLocalizations.of(context).translate('goalsHeading'),
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
              AppLocalizations.of(context).translate('goalsSubtitle'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 32.h),

          Expanded(
            child: ListView.builder(
              itemCount: goalsList.length,
              itemBuilder: (context, index) {
                final goal = goalsList[index];
                final isSelected = state.studentGoals.contains(goal['title']);
                final curtainIndex = index + 2;

                return CurtainDrop(
                  index: curtainIndex,
                  child: GestureDetector(
                    onTap: () => cubit.toggleGoal(goal['title'] as String),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(18.r),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : context.inputBgColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            goal['icon'] as IconData,
                            color: isSelected
                                ? AppColors.primary
                                : context.textMutedColor,
                            size: 24,
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Text(
                              goal['title'] as String,
                              style: TextStyle(
                                color: context.isDark ? AppColors.textMain : AppColors.textDark,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            onChanged: (_) =>
                                cubit.toggleGoal(goal['title'] as String),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
