import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/university_entity.dart';

class QuickInfoMetrics extends StatelessWidget {
  final UniversityEntity university;

  const QuickInfoMetrics({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    // 1. استخلاص البيانات بأمان (Defensive Programming)
    final firstProgram = university.programs.isNotEmpty
        ? university.programs.first
        : null;

    final String deadlineStr = firstProgram?.deadline ?? "";
    final int appFee = firstProgram?.applicationFee ?? 0;
    final int tuitionFee = firstProgram?.tuitionFeePerYear ?? 0;

    // 2. استخدام دالة المساعدة لمعالجة التاريخ (خارج الـ UI build منطقياً)
    final String remainingDaysText = _calculateRemainingDays(deadlineStr);

    // 3. تحديد الألوان بناءً على الحالة (بدون حسابات معقدة في الـ Build)
    final bool isUrgent =
        remainingDaysText.contains("In") &&
        int.tryParse(remainingDaysText.replaceAll(RegExp(r'[^0-9]'), '')) !=
            null &&
        int.parse(remainingDaysText.replaceAll(RegExp(r'[^0-9]'), '')) <= 7;

    final Color deadlineValColor = (isUrgent || remainingDaysText == 'Expired')
        ? const Color(0xFFEF4444)
        : const Color(0xFF475569);

    final Color deadlineBgColor = (isUrgent || remainingDaysText == 'Expired')
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFF1F5F9);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricItem(
          'Deadline',
          deadlineStr.isEmpty ? 'No deadline' : deadlineStr,
          remainingDaysText,
          deadlineValColor,
          deadlineBgColor,
        ),
        _buildMetricItem(
          'App Fee',
          appFee <= 0 ? "Free" : "€$appFee",
          'Non-refundable',
          const Color(0xFF0F172A),
          const Color(0xFFF1F5F9),
        ),
        _buildMetricItem(
          'Tuition',
          tuitionFee <= 0 ? "Free" : "€$tuitionFee",
          tuitionFee <= 0 ? 'Free Program' : 'Per Year',
          tuitionFee <= 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          tuitionFee <= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    String sub,
    Color valColor,
    Color bgColor,
  ) {
    return Container(
      width: 104.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF64748B),
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

// 🛡️ دالة معالجة التاريخ محمية تماماً من الكراش
String _calculateRemainingDays(String? deadlineStr) {
  if (deadlineStr == null || deadlineStr.isEmpty) return 'No deadline';

  try {
    DateTime? deadlineDate;

    // محاولة البارس الآمن
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

    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Today';
    return 'In $diff days';
  } catch (e) {
    return 'N/A';
  }
}
