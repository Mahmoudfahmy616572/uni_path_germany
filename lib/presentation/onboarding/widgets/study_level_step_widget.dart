import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/presentation/onboarding/cubit/onboarding_cubit.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_states.dart';

class StudyLevelStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const StudyLevelStepWidget({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final levels = [
      {
        'title': "Bachelor's Degree",
        'sub': 'Undergraduate programs',
        'icon': Icons.school_outlined,
      },
      {
        'title': "Master's Degree",
        'sub': 'Postgraduate programs',
        'icon': Icons.workspace_premium_outlined,
      },
      {
        'title': 'PhD / Doctorate',
        'sub': 'Research programs',
        'icon': Icons.biotech_outlined,
      },
      {
        'title': 'Graduate School',
        'sub': 'Structured doctoral programs',
        'icon': Icons.account_balance_outlined,
      },
      {
        'title': 'Summer Course',
        'sub': 'Short summer academic programs',
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'title': 'Short Course',
        'sub': 'Intensive short-term programs',
        'icon': Icons.timer_outlined,
      },
      {
        'title': 'Foundation / Preparatory',
        'sub': 'Studienkolleg & prep courses',
        'icon': Icons.trending_up_outlined,
      },
      {
        'title': 'Study Abroad / Exchange',
        'sub': 'Exchange semester programs',
        'icon': Icons.flight_outlined,
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
              AppLocalizations.of(context).translate('studyLevelHeading'),
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
              AppLocalizations.of(context).translate('studyLevelSubtitle'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                final isSelected = state.studyLevel == level['title'];
                final curtainIndex = index + 2;

                return CurtainDrop(
                  index: curtainIndex,
                  child: GestureDetector(
                    onTap: () =>
                        cubit.updateStudyLevel(level['title'] as String),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8.h),
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
                            level['icon'] as IconData,
                            color: isSelected
                                ? AppColors.primary
                                : context.textMutedColor,
                            size: 28,
                          ),
                          SizedBox(width: 16.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level['title'] as String,
                                style: TextStyle(
                                  color: context.isDark ? AppColors.textMain : AppColors.textDark,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                level['sub'] as String,
                                style: TextStyle(
                                  color: context.textMutedColor,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 22,
                            )
                          else
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.textMutedColor.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
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
