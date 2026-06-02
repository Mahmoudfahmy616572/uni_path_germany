import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class BudgetStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const BudgetStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    // خيارات الميزانية السنوية باليورو/الدولار
    final budgetRanges = [
      {
        'label': 'Tuition-Free / Low Fees',
        'sub': 'Under €3,000 / year (e.g., Public Germany)',
      },
      {'label': 'Medium Budget', 'sub': '€3,000 - €10,000 / year'},
      {'label': 'High Budget', 'sub': '€10,000 - €20,000 / year'},
      {'label': 'Premium Programs', 'sub': 'Over €20,000 / year'},
    ];

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is your tuition\nbudget per year?',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select the maximum tuition fees you can afford',
            style: TextStyle(color: AppColors.textGrey, fontSize: 15.sp),
          ),
          SizedBox(height: 32.h),

          Expanded(
            child: ListView.builder(
              itemCount: budgetRanges.length,
              itemBuilder: (context, index) {
                final budget = budgetRanges[index];
                // المقارنة مع المتغير المتسيف في الـ state
                final isSelected = state.tuitionBudget == budget['label'];

                return GestureDetector(
                  onTap: () => cubit.updateBudget(budget['label']!),
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
                          Icons.euro_symbol_rounded,
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
                                budget['label']!,
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                budget['sub']!,
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
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
                                color: AppColors.textGrey.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
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
