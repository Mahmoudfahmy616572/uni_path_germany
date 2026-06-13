import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';
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
          Text(
            'When do you want to\nstart studying?',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          SizedBox(height: 32.h),
          ...intakes.map((intake) {
            final isSelected = state.targetIntake == intake['name'];
            return GestureDetector(
              onTap: () => cubit.updateIntake(intake['name'] as String),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.inputBackground,
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
                          : AppColors.textGrey,
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
                              color: AppColors.textDark,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            intake['desc'] as String,
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
