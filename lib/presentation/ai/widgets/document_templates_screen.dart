import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';

class DocumentTemplatesScreen extends StatelessWidget {
  const DocumentTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('documentTemplates')),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.h),
          child: Container(color: AppColors.primary.withValues(alpha: 0.2), height: 2.h),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          _buildTemplateCard(
            context,
            icon: Icons.description_outlined,
            title: AppLocalizations.of(context).translate('cvGermanStyle'),
            subtitle: AppLocalizations.of(context).translate('cvTemplateSubtitle'),
            sections: [
              AppLocalizations.of(context).translate('cvSectionPersonal'),
              AppLocalizations.of(context).translate('cvSectionEducation'),
              AppLocalizations.of(context).translate('cvSectionWork'),
              AppLocalizations.of(context).translate('cvSectionSkills'),
              AppLocalizations.of(context).translate('cvSectionInterests'),
              AppLocalizations.of(context).translate('cvSectionReferences'),
            ],
            tip: AppLocalizations.of(context).translate('cvTip'),
            color: const Color(0xFF6366F1),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildTemplateCard(
            context,
            icon: Icons.article_outlined,
            title: AppLocalizations.of(context).translate('motivationLetterTemplate'),
            subtitle: AppLocalizations.of(context).translate('motivationLetterSubtitle'),
            sections: [
              AppLocalizations.of(context).translate('mlSectionHeader'),
              AppLocalizations.of(context).translate('mlSectionSubject'),
              AppLocalizations.of(context).translate('mlSectionPara1'),
              AppLocalizations.of(context).translate('mlSectionPara2'),
              AppLocalizations.of(context).translate('mlSectionPara3'),
              AppLocalizations.of(context).translate('mlSectionPara4'),
              AppLocalizations.of(context).translate('mlSectionClosing'),
            ],
            tip: AppLocalizations.of(context).translate('mlTip'),
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildTemplateCard(
            context,
            icon: Icons.receipt_long_outlined,
            title: AppLocalizations.of(context).translate('recommendationTemplate'),
            subtitle: AppLocalizations.of(context).translate('recommendationSubtitle'),
            sections: [
              AppLocalizations.of(context).translate('recSectionSubject'),
              AppLocalizations.of(context).translate('recSectionGreeting'),
              AppLocalizations.of(context).translate('recSectionIntro'),
              AppLocalizations.of(context).translate('recSectionRequest'),
              AppLocalizations.of(context).translate('recSectionDetails'),
              AppLocalizations.of(context).translate('recSectionDeadline'),
              AppLocalizations.of(context).translate('recSectionClosing'),
            ],
            tip: AppLocalizations.of(context).translate('recTip'),
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildTipCard(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> sections,
    required String tip,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textMain : const Color(0xFF1E293B),
                          )),
                      SizedBox(height: 4.h),
                      Text(subtitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sections
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sections.asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark ? AppColors.textMain : const Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                Divider(height: 24.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context).translate('proTip'),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context).translate('aiGeneratorPrompt'),
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? AppColors.textMuted : const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
