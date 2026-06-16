import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_theme.dart';

class PipelineMetricsHub extends StatelessWidget {
  final int upcomingDeadlines;
  final int matchAverage;

  const PipelineMetricsHub({
    super.key,
    required this.upcomingDeadlines,
    required this.matchAverage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(context,
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFFEF4444),
              title: 'upcomingDeadlines',
              value: '$upcomingDeadlines',
              subtitle: 'inTheNext30Days',
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildMetricCard(context,
              icon: Icons.folder_open_outlined,
              iconColor: const Color(0xFF10B981),
              title: 'yourMatchAverage',
              value: '$matchAverage%',
              subtitle: 'goodChance',
              subtitleColor: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    Color subtitleColor = const Color(0xFF64748B),
  }) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.translate(title),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  loc.translate(subtitle),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
