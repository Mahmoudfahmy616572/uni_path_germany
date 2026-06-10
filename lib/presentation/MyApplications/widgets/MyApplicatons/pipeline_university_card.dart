import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

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
        [app.hasTranscripts, app.hasCv, app.hasSop, app.hasBachelorCert].where((
          c,
        ) {
          if (c == null) return false;
          if (c is bool) return c; // لدعم البيانات القديمة لو لسه موجودة
          return c.toString().startsWith('http'); // لو رابط يبقى مرفوع
        }).length;

    final String remainingDaysText = _calculateRemainingDays(deadline);

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: Colors.white,
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
                  _buildLogo(app.logoText),
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
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Text(
                              degreeType,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              " • ",
                              style: TextStyle(color: Colors.grey.shade300),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaInfo(
                    Icons.calendar_today,
                    'Deadline',
                    remainingDaysText,
                    remainingDaysText == 'Expired'
                        ? Colors.red
                        : const Color(0xFF0F172A),
                  ),
                  _buildMetaInfo(
                    Icons.assignment_outlined,
                    'Docs',
                    '$docsCount/4 Ready',
                    docsCount == 4 ? Colors.green : const Color(0xFFF59E0B),
                  ),
                  _buildMetaInfo(
                    Icons.trending_up,
                    'Chance',
                    app.matchPercentage >= 70 ? "High" : "Medium",
                    const Color(0xFF10B981),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF1F5F9)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: const Color(0xFF475569),
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

  Widget _buildLogo(String text) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 44.w,
          height: 44.w,
          child: CircularProgressIndicator(
            value: match / 100,
            backgroundColor: const Color(0xFFF1F5F9),
            color: match >= 70
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            strokeWidth: 4,
          ),
        ),
        Text(
          '$match%',
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMetaInfo(IconData icon, String title, String sub, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: const Color(0xFF94A3B8)),
            SizedBox(width: 4.w),
            Text(
              title,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          sub,
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

  String _calculateRemainingDays(String deadlineStr) {
    try {
      DateTime deadline = DateFormat("d MMM yyyy").parse(deadlineStr);
      final diff = deadline.difference(DateTime.now()).inDays;
      if (diff < 0) return 'Expired';
      if (diff == 0) return 'Today';
      return 'In $diff days';
    } catch (e) {
      return deadlineStr;
    }
  }
}
