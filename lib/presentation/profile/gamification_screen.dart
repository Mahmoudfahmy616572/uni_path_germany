import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/gamification_service.dart' as gs;

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = gs.GamificationService.allStats;
    final earned = gs.GamificationService.getEarnedBadges();
    final progress = gs.GamificationService.overallProgress;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).translate('achievements'))),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events, size: 48.sp, color: Colors.white),
                SizedBox(height: 8.h),
                Text(AppLocalizations.of(context).translate('badgesEarned').replaceAll('{earned}', '${earned.length}').replaceAll('{total}', '${gs.GamificationService.totalCount}'),
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8.h,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(AppLocalizations.of(context).translate('percentComplete').replaceAll('{percent}', '${(progress * 100).round()}'),
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text(AppLocalizations.of(context).translate('yourStats'), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          _buildStatsRow(context, stats),
          SizedBox(height: 24.h),
          Text(AppLocalizations.of(context).translate('allBadges'), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          ...gs.GamificationService.badges.map((badge) => _buildBadgeCard(badge, earned.any((e) => e.id == badge.id), stats, isDark)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, int> stats) {
    final t = AppLocalizations.of(context).translate;
    final items = [
      (t('saved'), stats['universities_saved'] ?? 0, Icons.bookmark),
      (t('applied'), stats['applications_submitted'] ?? 0, Icons.send),
      (t('documents'), stats['documents_uploaded'] ?? 0, Icons.description),
    ];
    return Row(
      children: items.map((item) => Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Icon(item.$3, color: const Color(0xFF4F46E5), size: 24),
              SizedBox(height: 4.h),
              Text('${item.$2}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
              Text(item.$1, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildBadgeCard(gs.Badge badge, bool earned, Map<String, int> stats, bool isDark) {
    final progress = badge.progressTarget > 1
        ? ((stats[gs.GamificationService.statKeyFor(badge.id)] ?? 0) / badge.progressTarget).clamp(0.0, 1.0)
        : earned ? 1.0 : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: earned
              ? const Color(0xFFF59E0B)
              : isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: earned ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: earned ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              badge.icon,
              color: earned ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.title,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp,
                        color: earned ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
                Text(badge.description,
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B))),
                if (badge.progressTarget > 1 && !earned) ...[
                  SizedBox(height: 4.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(const Color(0xFF4F46E5)),
                      minHeight: 4.h,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (earned)
            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 22),
        ],
      ),
    );
  }
}
