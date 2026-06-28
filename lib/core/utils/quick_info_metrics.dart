import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/university_entity.dart';

class QuickInfoMetrics extends StatelessWidget {
  final UniversityEntity university;

  const QuickInfoMetrics({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final firstProgram = university.programs.isNotEmpty
        ? university.programs.first
        : null;

    final String deadlineStr = firstProgram?.deadline ?? "";
    final int appFee = firstProgram?.applicationFee ?? 0;
    final int tuitionFee = firstProgram?.tuitionFeePerYear ?? 0;

    final String remainingDaysText = _calculateRemainingDays(context, deadlineStr);

    final bool isUrgent =
        remainingDaysText.contains(loc.translate('inDays').replaceAll('%d', '')) &&
        int.tryParse(remainingDaysText.replaceAll(RegExp(r'[^0-9]'), '')) !=
            null &&
        int.parse(remainingDaysText.replaceAll(RegExp(r'[^0-9]'), '')) <= 7;

    final Color deadlineValColor = (isUrgent || remainingDaysText == loc.translate('expired'))
        ? const Color(0xFFEF4444)
        : context.isDark ? AppColors.textMuted : const Color(0xFF475569);

    final Color deadlineBgColor = (isUrgent || remainingDaysText == loc.translate('expired'))
        ? context.isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2)
        : context.isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _buildMetricItem(
          context,
          loc.translate('deadline'),
          deadlineStr.isEmpty ? loc.translate('noDeadline') : deadlineStr,
          remainingDaysText,
          deadlineValColor,
          deadlineBgColor,
        )),
        SizedBox(width: 8.w),
        Flexible(child: _buildMetricItem(
          context,
          'App Fee',
          appFee <= 0 ? loc.translate('free') : "€$appFee",
          loc.translate('nonRefundable'),
          context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
          context.isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
        )),
        SizedBox(width: 8.w),
        Flexible(child: _buildMetricItem(
          context,
          'Tuition',
          tuitionFee <= 0 ? loc.translate('free') : "€$tuitionFee",
          tuitionFee <= 0 ? loc.translate('freeProgram') : loc.translate('perYear'),
          tuitionFee <= 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          tuitionFee <= 0
              ? context.isDark ? AppColors.badgeGreen.withValues(alpha: 0.15) : const Color(0xFFDCFCE7)
              : context.isDark ? AppColors.badgeAmber.withValues(alpha: 0.15) : const Color(0xFFFEF3C7),
        )),
      ],
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    String sub,
    Color valColor,
    Color bgColor,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          SizedBox(
            height: 20.h,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: valColor,
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              sub,
              style: TextStyle(
                fontSize: 9.sp,
                color: valColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _calculateRemainingDays(BuildContext context, String? deadlineStr) {
  final loc = AppLocalizations.of(context);
  if (deadlineStr == null || deadlineStr.isEmpty) return loc.translate('noDeadline');

  try {
    DateTime? deadlineDate;

    deadlineDate = DateTime.tryParse(deadlineStr);
    if (deadlineDate == null) {
      try {
        deadlineDate = DateFormat("d MMM yyyy").parse(deadlineStr);
      } catch (_) {
        deadlineDate = DateFormat("d MMMM yyyy").parse(deadlineStr);
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(
      deadlineDate.year,
      deadlineDate.month,
      deadlineDate.day,
    );

    final diff = targetDate.difference(today).inDays;

    if (diff < 0) return loc.translate('expired');
    if (diff == 0) return loc.translate('today');
    return loc.translate('inDays').replaceAll('%d', diff.toString());
  } catch (e) {
    return loc.translate('notAvailable');
  }
}
