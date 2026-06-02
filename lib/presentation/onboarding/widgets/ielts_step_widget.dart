import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class IeltsStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const IeltsStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'English Language\nProficiency',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Have you taken the IELTS exam?',
            style: TextStyle(color: AppColors.textGrey, fontSize: 15.sp),
          ),
          SizedBox(height: 40.h),

          // خيار: نعم (Yes)
          _buildSelectionCard(
            title: 'Yes, I have an IELTS score',
            subtitle: 'You will enter your band score next',
            icon: Icons.check_circle_outline,
            isSelected: state.hasIELTS == true,
            onTap: () => cubit.updateIeltsStatus(true),
          ),

          SizedBox(height: 16.h),

          // خيار: لا (No)
          _buildSelectionCard(
            title: 'No, I don\'t have one',
            subtitle: 'Skip language score requirements',
            icon: Icons.cancel_outlined,
            isSelected: state.hasIELTS == false,
            onTap: () => cubit.updateIeltsStatus(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
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
              icon,
              color: isSelected ? AppColors.primary : AppColors.textGrey,
              size: 32,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.radio_button_checked, color: AppColors.primary)
            else
              Icon(
                Icons.radio_button_off,
                color: AppColors.textGrey.withOpacity(0.4),
              ),
          ],
        ),
      ),
    );
  }
}
