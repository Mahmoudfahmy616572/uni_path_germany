import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/domain/entities/university_entity.dart';

import '../../../core/utils/requirements_check_list.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';

class AdmissionAnalysisTables extends StatelessWidget {
  final UniversityEntity university;

  const AdmissionAnalysisTables({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityDetailsCubit, UniversityDetailsState>(
      builder: (context, state) {
        // 🎯 التصليح السحري: سحب القيم بأمان من أول برنامج متاح في الجامعة لتجنب الـ Errors
        final bool hasPrograms = university.programs.isNotEmpty;
        final firstProgram = hasPrograms ? university.programs.first : null;

        // حساب النسب بناءً على الكيان الجديد المستقل
        double academicScore = 0.85; // نسبة ثابتة أو ديناميكية للـ Major Match

        // تشيك الـ GPA من أول برنامج متاح
        double gpaScore = (firstProgram != null && firstProgram.requiredGpa > 0)
            ? 0.80
            : 0.50;

        // تشيك الـ IELTS من أول برنامج متاح
        double englishScore =
            (firstProgram != null && !firstProgram.requiresIelts) ? 0.95 : 0.70;

        // تشيك الـ CV والخبرة من حقول الجامعة
        double workExpScore = (university.hasCv ?? false) ? 0.75 : 0.30;

        // 🎯 الاستفادة من النسبة الكلية المحسوبة مسبقاً بدقة بالمعادلة الألمانية جوه الـ Entity
        // لو مبعوتة بـ 0 أو مش موجودة بنحسبها مجمعاً كـ fallback
        double overallScore = university.matchPercentage > 0
            ? (university.matchPercentage / 100)
            : (academicScore + gpaScore + englishScore + workExpScore) / 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الجزء العلوي: تحليل الـ Profile
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Your Profile Match',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            _buildMetricRowInline('Academic', academicScore),
            SizedBox(height: 8.h),
            _buildMetricRowInline('GPA Match', gpaScore),
            SizedBox(height: 8.h),
            _buildMetricRowInline('English', englishScore),
            SizedBox(height: 8.h),
            _buildMetricRowInline('Experience', workExpScore),

            // صف الـ Overall المجموع
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
            ),
            _buildMetricRowInline(
              'Overall Match',
              overallScore,
              isOverall: true,
            ),

            SizedBox(height: 24.h),

            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Requirements Checklist',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            RequirementsChecklistList(university: university),
          ],
        );
      },
    );
  }

  // دالة بناء الصفوف ومميز فيها الـ Overall بسلاسة
  Widget _buildMetricRowInline(
    String title,
    double score, {
    bool isOverall = false,
  }) {
    final int percentage = (score * 100).round().clamp(0, 100);

    // لون الـ Overall متميز بأزرق براند شيك والترتيب الأخضر والبرتقالي للباقي
    final Color barColor = isOverall
        ? const Color(0xFF4F46E5)
        : (percentage >= 70
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B));

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isOverall ? FontWeight.bold : FontWeight.normal,
              color: isOverall
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              minHeight: isOverall ? 8 : 6, // تمييز الـ Overall بالسمك
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: barColor,
          ),
        ),
      ],
    );
  }
}
