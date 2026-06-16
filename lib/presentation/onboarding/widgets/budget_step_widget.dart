import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class BudgetStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const BudgetStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
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
          CurtainDrop(
            index: 0,
            child: Text(
              AppLocalizations.of(context).translate('budgetHeading'),
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
              AppLocalizations.of(context).translate('budgetSubtitle'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 32.h),

          Expanded(
            child: ListView.builder(
              itemCount: budgetRanges.length,
              itemBuilder: (context, index) {
                final budget = budgetRanges[index];
                final isSelected = state.tuitionBudget == budget['label'];
                final curtainIndex = index + 2;

                return CurtainDrop(
                  index: curtainIndex,
                  child: GestureDetector(
                    onTap: () => cubit.updateBudget(budget['label']!),
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
                            Icons.euro_symbol_rounded,
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
                                  budget['label']!,
                                  style: TextStyle(
                                    color: context.isDark ? AppColors.textMain : AppColors.textDark,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  budget['sub']!,
                                  style: TextStyle(
                                    color: context.textMutedColor,
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
                                  color: AppColors.textGrey.withValues(alpha: 0.4),
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
