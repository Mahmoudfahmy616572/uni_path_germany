import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
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
          CurtainDrop(
            index: 0,
            child: Text(
              AppLocalizations.of(context).translate('ieltsHeading'),
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
              AppLocalizations.of(context).translate('ieltsSubtitle'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
              child: ListView(
                children: [
                  CurtainDrop(
                    index: 2,
                    child: _buildSelectionCard(
                      context,
                      title: 'IELTS',
                      subtitle: 'International English Language Testing System',
                      icon: Icons.check_circle_outline,
                      isSelected: state.testType == 'ielts',
                      onTap: () => cubit.updateTestType('ielts'),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CurtainDrop(
                    index: 3,
                    child: _buildSelectionCard(
                      context,
                      title: 'TOEFL',
                      subtitle: 'Test of English as a Foreign Language',
                      icon: Icons.language_outlined,
                      isSelected: state.testType == 'toefl',
                      onTap: () => cubit.updateTestType('toefl'),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CurtainDrop(
                    index: 4,
                    child: _buildSelectionCard(
                      context,
                      title: 'MOI',
                      subtitle: 'Medium of Instruction certificate',
                      icon: Icons.school_outlined,
                      isSelected: state.testType == 'moi',
                      onTap: () => cubit.updateTestType('moi'),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CurtainDrop(
                    index: 5,
                    child: _buildSelectionCard(
                      context,
                      title: 'None of the above',
                      subtitle: 'I don\'t have any English certificate',
                      icon: Icons.cancel_outlined,
                      isSelected: state.testType == 'none',
                      onTap: () => cubit.updateTestType('none'),
                    ),
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
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
              icon,
              color: isSelected ? AppColors.primary : context.textMutedColor,
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
                      color: context.isDark ? AppColors.textMain : AppColors.textDark,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.textMutedColor,
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
                color: context.textMutedColor.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}
