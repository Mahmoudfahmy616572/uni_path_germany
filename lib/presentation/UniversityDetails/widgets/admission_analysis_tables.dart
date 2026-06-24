import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/domain/entities/university_entity.dart';
import 'package:germany_travel/domain/entities/program_entity.dart';

import '../../../core/utils/match_score_calculator.dart';
import '../../../core/utils/requirements_check_list.dart';
import '../../../core/widgets/animated_match_score.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';

class AdmissionAnalysisTables extends StatelessWidget {
  final UniversityEntity university;

  const AdmissionAnalysisTables({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityDetailsCubit, UniversityDetailsState>(
      builder: (context, state) {
      // 🎯 استخدم البرامج المحدَّثة من الـ state (بعد إعادة حساب matchScore)
      final List<ProgramEntity> programs = state is UniversitySaveStatus
          ? state.displayedPrograms
          : university.programs;

      // Find best-matching program (highest matchScore) for representative metrics
      final ProgramEntity? bestProgram = programs.isEmpty
          ? null
          : programs.reduce(
              (a, b) => a.matchScore >= b.matchScore ? a : b,
            );

      // Get student profile from state (populated by checkInitialSaveStatus)
      final Map<String, dynamic>? studentProfile =
          (state is UniversitySaveStatus) ? state.studentProfile : null;

        // Calculate real breakdown using MatchScoreCalculator
        final breakdown = (studentProfile != null && bestProgram != null)
            ? MatchScoreCalculator.getBreakdown(
                studentProfile: studentProfile,
                programRequiredGpa: bestProgram.requiredGpa,
                programRequiresIelts: bestProgram.requiresIelts,
                programMinIelts: bestProgram.minIeltsScore,
                programAcceptsMoi: bestProgram.acceptsMoi,
                programMajor: bestProgram.major,
                programName: bestProgram.programName,
                programIntake: bestProgram.intakeType,
                programLanguage: bestProgram.instructionLanguage,
                programDegree: bestProgram.degreeType,
              )
            : null;

        // Extract scores from breakdown (0.0 to 1.0 for progress bars)
        final double academicScore = breakdown != null
            ? (breakdown['breakdown']['major']['score'] as int) / 25.0
            : 0.0;
        final double gpaScore = breakdown != null
            ? (breakdown['breakdown']['gpa']['score'] as int) / 35.0
            : 0.0;
        final double englishScore = breakdown != null
            ? (breakdown['breakdown']['ielts']['score'] as int) / 15.0
            : 0.0;
        final double workExpScore = breakdown != null
            ? (breakdown['breakdown']['language']['score'] as int) / 15.0
            : 0.0;

        final double overallScore = breakdown != null
            ? (breakdown['total'] as int) / 100.0
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الجزء العلوي: تحليل الـ Profile
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                'Your Profile Match',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            _buildMetricRowInline('Major Match', academicScore),
            SizedBox(height: 8.h),
            _buildMetricRowInline('GPA Match', gpaScore),
            SizedBox(height: 8.h),
            _buildMetricRowInline('English', englishScore),
            SizedBox(height: 8.h),
            _buildMetricRowInline('Language Pref', workExpScore),

            // صف الـ Overall المجموع
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
            ),
            _buildMetricRowInline(
              'Overall Match',
              overallScore,
              isOverall: true,
            ),

            SizedBox(height: 24.h),

            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
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
          width: 90.w,
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
        AnimatedScoreText(
          score: percentage,
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
