import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class MajorStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const MajorStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final List<String> majors = [
      'Computer Science',
      'Computer Science & IT',
      'Information Systems',
      'Artificial Intelligence',
      'Cybersecurity',
      'Bioinformatics',
      'Software Engineering',
      'Data Science',
      'Information Technology',
      'Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
      'Aerospace Engineering',
      'Automotive Engineering',
      'Chemical Engineering',
      'Energy Engineering',
      'Robotics',
      'Business Administration',
      'Business & Management',
      'Economics',
      'Finance',
      'Management',
      'Marketing',
      'Medicine',
      'Healthcare',
      'Pharmaceutical Sciences',
      'Natural Sciences',
      'Mathematics',
      'Environmental Science',
      'Physics',
      'Chemistry',
      'Social Sciences',
      'Political Science',
      'Law',
    ];

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurtainDrop(
            index: 0,
            child: Text(
              AppLocalizations.of(context).translate('majorHeading'),
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
              AppLocalizations.of(context).translate('majorSubtitle'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 32.h),

          Expanded(
            child: ListView.builder(
              itemCount: majors.length,
              itemBuilder: (context, index) {
                final majorName = majors[index];
                final isSelected = state.fieldOfInterest == majorName;
                final curtainIndex = index + 2;

                return CurtainDrop(
                  index: curtainIndex,
                  child: GestureDetector(
                    onTap: () => cubit.updateField(majorName),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
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
                          Expanded(
                            child: Text(
                              majorName,
                              style: TextStyle(
                                color: context.isDark ? AppColors.textMain : AppColors.textDark,
                                fontSize: 16.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
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
