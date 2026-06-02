import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class GoalsStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const GoalsStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    // قائمة الأهداف المقترحة للدراسة في الخارج
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
          Text(
            'What are your primary\nstudy goals?',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select all that apply to your future plans',
            style: TextStyle(color: AppColors.textGrey, fontSize: 15.sp),
          ),
          SizedBox(height: 32.h),

          Expanded(
            child: ListView.builder(
              itemCount: goalsList.length,
              itemBuilder: (context, index) {
                final goal = goalsList[index];
                // التأكد إذا كان الهدف موجود في الـ List الحالية بالـ state
                final isSelected = state.studentGoals.contains(goal['title']);

                return GestureDetector(
                  onTap: () => cubit.toggleGoal(goal['title'] as String),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.inputBackground,
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
                              : AppColors.textGrey,
                          size: 24,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            goal['title'] as String,
                            style: TextStyle(
                              color: AppColors.textDark,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
