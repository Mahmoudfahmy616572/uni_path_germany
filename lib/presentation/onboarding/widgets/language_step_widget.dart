import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class LanguageStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const LanguageStepWidget({
    super.key,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final langs = [
      {
        'name': 'English',
        'desc': 'Only English-taught programs',
        'icon': Icons.language,
      },
      {
        'name': 'German',
        'desc': 'Only German-taught programs',
        'icon': Icons.translate,
      },
      {
        'name': 'Both',
        'desc': 'I am flexible with both languages',
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
              AppLocalizations.of(context).translate('langHeading'),
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
              AppLocalizations.of(context).translate('langSubtitle'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 32.h),
          Expanded(
            child: ListView.builder(
              itemCount: langs.length,
              itemBuilder: (context, index) {
                final lang = langs[index];
                final isSelected = state.languagePreference == lang['name'];
                final curtainIndex = index + 2;

                return CurtainDrop(
                  index: curtainIndex,
                  child: GestureDetector(
                    onTap: () => cubit.updateLanguage(lang['name'] as String),
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
                            lang['icon'] as IconData,
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
                                  lang['name'] as String,
                                  style: TextStyle(
                                    color: context.isDark ? AppColors.textMain : AppColors.textDark,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  lang['desc'] as String,
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
