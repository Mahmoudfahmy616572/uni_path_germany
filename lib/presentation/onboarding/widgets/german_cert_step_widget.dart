import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class GermanCertStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const GermanCertStepWidget({super.key, required this.cubit, required this.state});

  static const _certTypes = ['TestDaF', 'Goethe', 'DSH', 'Telc', 'ÖSD'];
  static const _certLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurtainDrop(
            index: 0,
            child: Text(
              t.translate('germanCertTitle'),
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
              t.translate('germanCertDesc'),
              style: TextStyle(color: context.textMutedColor, fontSize: 15.sp),
            ),
          ),
          SizedBox(height: 24.h),
          if (!state.hasGermanCert)
            CurtainDrop(
              index: 2,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => cubit.updateGermanCert(hasCert: true),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: Text(
                    t.translate('addGermanCert'),
                    style: TextStyle(fontSize: 16.sp, color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            )
          else ...[
            CurtainDrop(
              index: 2,
              child: Text(
                t.translate('certificateType'),
                style: TextStyle(
                  color: context.isDark ? AppColors.textMain : AppColors.textDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView(
                children: [
                  ..._certTypes.map(
                    (type) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: CurtainDrop(
                        index: 3,
                        child: _buildSelectionCard(
                          context,
                          title: type,
                          isSelected: state.germanCertType == type,
                          onTap: () => cubit.updateGermanCert(hasCert: true, type: type, level: state.germanCertLevel),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CurtainDrop(
                    index: 4,
                    child: Text(
                      t.translate('cefrLevel'),
                      style: TextStyle(
                        color: context.isDark ? AppColors.textMain : AppColors.textDark,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ..._certLevels.map(
                    (level) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: CurtainDrop(
                        index: 5,
                        child: _buildSelectionCard(
                          context,
                          title: level,
                          isSelected: state.germanCertLevel == level,
                          onTap: () => cubit.updateGermanCert(hasCert: true, type: state.germanCertType, level: level),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CurtainDrop(
                    index: 6,
                      child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => cubit.updateGermanCert(hasCert: false),
                        icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
                        label: Text(
                          t.translate('removeGermanCert'),
                          style: TextStyle(fontSize: 16.sp, color: const Color(0xFFEF4444)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
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
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.isDark ? AppColors.textMain : AppColors.textDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
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
