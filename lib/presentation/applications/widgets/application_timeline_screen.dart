import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../domain/entities/university_entity.dart';

class _TimelineStep {
  final String title;
  final String subtitle;
  final String date;
  final bool done;
  final bool urgent;
  _TimelineStep({required this.title, required this.subtitle, required this.date, this.done = false, this.urgent = false});
}

List<_TimelineStep> _buildSteps(BuildContext context, UniversityEntity uni, String? deadline) {
  final t = AppLocalizations.of(context).translate;
  final now = DateTime.now();
  final deadlineDate = deadline != null ? DateTime.tryParse(deadline) : null;

  return [
    _TimelineStep(
      title: t('stepPrepareDocuments'),
      subtitle: 'Transcripts, certificates, CV, SOP',
      date: deadlineDate != null ? deadlineDate.subtract(const Duration(days: 60)).toString().substring(0, 10) : 'ASAP',
      done: uni.hasCv is String && (uni.hasCv as String).startsWith('http'),
    ),
    _TimelineStep(
      title: 'Language Test',
      subtitle: 'IELTS / TOEFL / TestDaF',
      date: deadlineDate != null ? deadlineDate.subtract(const Duration(days: 45)).toString().substring(0, 10) : 'Check requirements',
      done: false,
    ),
    _TimelineStep(
      title: t('stepAttendInterview'),
      subtitle: uni.name,
      date: deadline ?? 'TBD',
      urgent: deadlineDate != null && deadlineDate.difference(now).inDays < 30,
    ),
    _TimelineStep(
      title: 'Visa Application',
      subtitle: 'German embassy / consulate',
      date: deadlineDate != null ? deadlineDate.add(const Duration(days: 7)).toString().substring(0, 10) : 'After acceptance',
    ),
    _TimelineStep(
      title: 'Travel & Relocate',
      subtitle: 'Find housing, enroll',
      date: deadlineDate != null ? deadlineDate.add(const Duration(days: 60)).toString().substring(0, 10) : 'Semester start',
    ),
  ];
}

class ApplicationTimelineScreen extends StatelessWidget {
  final List<UniversityEntity> applications;
  const ApplicationTimelineScreen({super.key, this.applications = const []});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).translate('applicationTimeline'))),
      body: applications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timeline, size: 48.sp, color: const Color(0xFF94A3B8)),
                  SizedBox(height: 16.h),
                  Text(AppLocalizations.of(context).translate('saveUniversitiesFirstTimeline'),
                      style: TextStyle(fontSize: 16.sp, color: const Color(0xFF64748B))),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: applications.length,
              itemBuilder: (context, index) => _buildUniversityTimeline(
                context, applications[index], isDark),
            ),
    );
  }

  Widget _buildUniversityTimeline(BuildContext context, UniversityEntity uni, bool isDark) {
    final program = uni.programs.isNotEmpty ? uni.programs.first : null;
    final steps = _buildSteps(context, uni, program?.deadline);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                  child: Icon(Icons.school, color: const Color(0xFF4F46E5), size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(uni.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp,
                            color: isDark ? AppColors.textMain : const Color(0xFF0F172A)),
                        softWrap: true),
                    if (program != null)
                      Text('${program.programName} • ${program.degreeType}',
                          style: TextStyle(fontSize: 12.sp,
                              color: isDark ? AppColors.textMuted : const Color(0xFF64748B)),
                          softWrap: true),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return _buildStep(i, step, steps.length, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildStep(int index, _TimelineStep step, int total, bool isDark) {
    final color = step.done ? const Color(0xFF16A34A) : step.urgent ? const Color(0xFFDC2626) : const Color(0xFF4F46E5);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24.w,
            child: Column(
              children: [
                Container(
                  width: 16.r,
                  height: 16.r,
                  decoration: BoxDecoration(
                    color: step.done ? const Color(0xFF16A34A) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: step.done
                      ? Icon(Icons.check, size: 10.sp, color: Colors.white)
                      : null,
                ),
                if (index < total - 1)
                  Expanded(
                    child: VerticalDivider(
                      width: 24.w,
                      thickness: 1.5.r,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: index < total - 1 ? 12.h : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp,
                          color: isDark ? AppColors.textMain : const Color(0xFF0F172A)),
                      softWrap: true),
                  SizedBox(height: 2.h),
                  Text(step.subtitle,
                      style: TextStyle(fontSize: 12.sp,
                          color: isDark ? AppColors.textMuted : const Color(0xFF64748B)),
                      softWrap: true),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12.r, color: color),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(step.date,
                            style: TextStyle(fontSize: 11.sp, color: color, fontWeight: step.urgent ? FontWeight.bold : FontWeight.normal),
                            softWrap: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
