import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/deadline_parser.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../domain/entities/university_entity.dart';

class PipelineUniversityCard extends StatelessWidget {
  final UniversityEntity app;
  final VoidCallback onTap;

  const PipelineUniversityCard({
    super.key,
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final program = app.programs.isNotEmpty ? app.programs.first : null;
    final String programName = program?.programName ?? "General Track";
    final String degreeType = program?.degreeType ?? "Master";
    final String deadline = program?.deadline ?? "No Deadline";

    // 🎯 تصليح الحسبة هنا: نعد المستندات اللي قيمتها عبارة عن رابط (تبدأ بـ http)
    int docsCount =
        [app.hasTranscripts, app.hasCv, app.hasSop, app.hasBachelorCert, app.hasLanguageCert].where((
          c,
        ) {
          if (c == null) return false;
          if (c is bool) return c; // لدعم البيانات القديمة لو لسه موجودة
          return c.toString().startsWith('http'); // لو رابط يبقى مرفوع
        }).length;

    final String remainingDaysText = _calculateRemainingDays(context, deadline);
    final int? remainingDays = DeadlineParser.remainingDays(deadline);

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
                        side: BorderSide(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: context.isDark ? AppColors.darkCardBg : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(context, app.logoText),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Text(
                              degreeType,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              " • ",
                              style: TextStyle(color: context.isDark ? AppColors.textMuted : Colors.grey.shade300),
                            ),
                            Expanded(
                              child: Text(
                                programName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildMatchBadge(app.matchPercentage),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 44.h,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetaInfo(context,
                        Icons.calendar_today,
                        AppLocalizations.of(context).translate('deadline'),
                        remainingDaysText,
                        remainingDays != null && remainingDays < 0
                            ? Colors.red
                            : context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
                      ),
                    ),
                    Expanded(
                      child: _buildMetaInfo(context,
                        Icons.assignment_outlined,
                        AppLocalizations.of(context).translate('docs'),
                        '$docsCount/5 Ready',
                        docsCount == 5
                            ? Colors.green
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    Expanded(
                      child: _buildMetaInfo(context,
                        Icons.trending_up,
                        AppLocalizations.of(context).translate('chance'),
                        app.matchPercentage >= 70 ? AppLocalizations.of(context).translate('high') : AppLocalizations.of(context).translate('medium'),
                        const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 32.h, color: context.isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
        side: BorderSide(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('viewDetails'),
                        style: TextStyle(
                          color: context.isDark ? AppColors.textMuted : const Color(0xFF475569),
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildAiActionButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, String text) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkSurface : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF4F46E5),
        ),
      ),
    );
  }

  Widget _buildMatchBadge(int match) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: match.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44.w,
              height: 44.w,
              child: CircularProgressIndicator(
                value: value / 100,
                backgroundColor: context.isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                color: match >= 70
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                strokeWidth: 4,
              ),
            ),
            Text(
              '${value.round()}%',
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetaInfo(BuildContext context, IconData icon, String title, String sub, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF94A3B8)),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAiActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: IconButton(
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        onPressed: () {},
      ),
    );
  }

  String _calculateRemainingDays(BuildContext context, String deadlineStr) {
    final loc = AppLocalizations.of(context);
    final days = DeadlineParser.remainingDays(deadlineStr);
    if (days == null) return deadlineStr;
    if (days < 0) return loc.translate('expired');
    if (days == 0) return loc.translate('today');
    return loc.translate('inDays').replaceAll('%d', days.toString());
  }
}
