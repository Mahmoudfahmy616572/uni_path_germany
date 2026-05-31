import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/university_model.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';
import 'requirements_check_list.dart';

class AdmissionAnalysisTables extends StatelessWidget {
  final UniversityModel university;

  const AdmissionAnalysisTables({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityDetailsCubit, UniversityDetailsState>(
      builder: (context, state) {
        // حساب النسب الحقيقية
        double academicScore = 0.85;
        double gpaScore = (university.requiredGpa != null) ? 0.80 : 0.50;
        double englishScore = (!university.requiresIelts) ? 0.95 : 0.70;
        double workExpScore = university.hasCv ? 0.75 : 0.30;

        // 🔥 حساب النسبة المجمعة (Overall) بجمع الـ 4 نسب وقسمتهم
        double overallScore =
            (academicScore + gpaScore + englishScore + workExpScore) / 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الجزء العلوي: تحليل الـ Profile
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Your Profile Match',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            _buildMetricRowInline('Academic', academicScore),
            const SizedBox(height: 8),
            _buildMetricRowInline('GPA Match', gpaScore),
            const SizedBox(height: 8),
            _buildMetricRowInline('English', englishScore),
            const SizedBox(height: 8),
            _buildMetricRowInline('Experience', workExpScore),

            // 🔥 صف الـ Overall المجموع
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
            ),
            _buildMetricRowInline(
              'Overall Match',
              overallScore,
              isOverall: true,
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Requirements Checklist',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            RequirementsChecklistList(university: university),
          ],
        );
      },
    );
  }

  // تحديث الدالة عشان تستقبل isOverall وتميز صف المجموع
  Widget _buildMetricRowInline(
    String title,
    double score, {
    bool isOverall = false,
  }) {
    final int percentage = (score * 100).round();
    // لون الـ Overall بيبقى مختلف عشان يشد العين (مثلاً أزرق غامق)
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
              fontSize: 12,
              fontWeight: isOverall ? FontWeight.bold : FontWeight.normal,
              color: isOverall
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: isOverall ? 8 : 6, // الـ Overall تخين شوية عشان يتميز
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: barColor,
          ),
        ),
      ],
    );
  }
}
