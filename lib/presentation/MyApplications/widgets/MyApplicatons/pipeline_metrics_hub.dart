import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/deadline_parser.dart';
import '../../../../domain/entities/university_entity.dart';

class PipelineMetricsHub extends StatelessWidget {
  final List<UniversityEntity> applications;
  final Map<String, int> statusCounts;

  const PipelineMetricsHub({
    super.key,
    required this.applications,
    required this.statusCounts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final upcomingDeadlines = applications
        .where((uni) => uni.programs.any((p) {
              if (p.deadline == null || p.deadline!.isEmpty) return false;
              final days = DeadlineParser.remainingDays(p.deadline!);
              return days != null && days >= 0 && days <= 30;
            }))
        .length;

    final total = applications.length;
    final appliedCount = (statusCounts['applied'] ?? 0) + (statusCounts['waiting'] ?? 0) + (statusCounts['accepted'] ?? 0);
    final matchAvg = total > 0
        ? (applications.fold<int>(0, (sum, u) => sum + u.matchPercentage) / total).round()
        : 0;

    final statusColors = {
      'saved': const Color(0xFF94A3B8),
      'preparing': const Color(0xFFF59E0B),
      'applied': const Color(0xFF3B82F6),
      'waiting': const Color(0xFF8B5CF6),
      'accepted': const Color(0xFF10B981),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard(
              context,
              icon: Icons.calendar_today,
              label: AppLocalizations.of(context).translate('upcomingDeadlinesShort'),
              value: '$upcomingDeadlines',
              color: upcomingDeadlines > 0 ? Colors.redAccent : AppColors.primary,
              isDark: isDark,
              onTap: () => context.push('/deadline-calendar'),
            )),
            SizedBox(width: 12.w),
            Expanded(child: _buildMetricCard(
              context,
              icon: Icons.trending_up,
              label: AppLocalizations.of(context).translate('avgMatch'),
              value: '$matchAvg%',
              color: AppColors.primary,
              isDark: isDark,
            )),
            SizedBox(width: 12.w),
            Expanded(child: _buildMetricCard(
              context,
              icon: Icons.checklist,
              label: AppLocalizations.of(context).translate('appliedShort'),
              value: '$appliedCount/$total',
              color: const Color(0xFF10B981),
              isDark: isDark,
            )),
          ],
        ),
        SizedBox(height: 16.h),
        if (total > 0) ...[
          _buildStatusBar(context, isDark, statusColors),
          SizedBox(height: 8.h),
          _buildStatusLegend(context, isDark, statusColors),
        ],
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22.sp),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textMain : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, bool isDark, Map<String, Color> colors) {
    final totalCount = statusCounts.values.fold<int>(0, (a, b) => a + b);
    if (totalCount == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        height: 8.h,
        child: Row(
          children: [
            for (final entry in ['saved', 'preparing', 'applied', 'waiting', 'accepted'])
              if ((statusCounts[entry] ?? 0) > 0)
                Expanded(
                  flex: statusCounts[entry]!,
                  child: Container(color: colors[entry]),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegend(BuildContext context, bool isDark, Map<String, Color> colors) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 4.h,
      children: ['saved', 'preparing', 'applied', 'waiting', 'accepted'].map((key) {
        final count = statusCounts[key] ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                color: colors[key],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              '${AppLocalizations.of(context).translate(key)} ($count)',
              style: TextStyle(
                fontSize: 10.sp,
                color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
