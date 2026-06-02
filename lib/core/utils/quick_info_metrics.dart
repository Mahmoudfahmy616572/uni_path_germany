import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart'; // 🔥 مهم جداً عشان الـ DateFormat يشتغل بدون مشاكل

import '../../data/models/university_model.dart';

class QuickInfoMetrics extends StatelessWidget {
  final UniversityModel university;

  // جعلنا الـ Constructor ثابت (const) وده أفضل للأداء في فلاتر
  const QuickInfoMetrics({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    //  1. تجهيز تاريخ الديدلاين مع قيمة افتراضية آمنة
    final String deadlineStr = university.deadline ?? "15 Jul 2026";

    int daysLeft = 30; // القيمة الافتراضية لو حصل مشكلة في قراءة التاريخ
    try {
      DateTime? deadlineDate = DateTime.tryParse(deadlineStr);
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
      daysLeft = targetDate.difference(today).inDays;
    } catch (_) {}

    // 🎨 3. تحديد ألوان كارت الـ Deadline بناءً على المدة المتبقية (أقل من أسبوع = خطر)
    final bool isUrgent = daysLeft <= 7;
    final Color deadlineValColor = isUrgent
        ? const Color(0xFFEF4444)
        : const Color(0xFF475569); // أحمر أو رمادي داكن
    final Color deadlineBgColor = isUrgent
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFF1F5F9); // خلفية حمراء فاتحة أو رمادي ناعم

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // كارت الـ Deadline بالألوان الذكية والنص الديناميكي
        _buildMetricItem(
          'Deadline',
          deadlineStr,
          _calculateRemainingDays(deadlineStr),
          deadlineValColor,
          deadlineBgColor,
        ),
        // كارت مصاريف التقديم
        _buildMetricItem(
          'Application Fee',
          "${university.applicationFee}",
          'Non-refundable',
          const Color(0xFF0F172A),
          const Color(0xFFF1F5F9),
        ),
        // كارت مصاريف الدراسة (مجاني دايماً في الجامعات الحكومية الألمانية)
        _buildMetricItem(
          'Tuition (Year)',
          '${university.tuitionFeePerYear != null ? university.tuitionFeePerYear : "Free"}',
          'Free Program',
          const Color(0xFF10B981),
          const Color(0xFFDCFCE7),
        ),
      ],
    );
  }

  // الـ Widget الخاصة ببناء الكارت الصغير (تم إضافة FittedBox لتأمين النصوص الطويلة)
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
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          // استخدام FittedBox عشان لو صيغة التاريخ طويلة شوية متعملش Overflow وتصغر تلقائي
          SizedBox(
            height: 20.h,
            child: Alignment.centerLeft == Alignment.centerLeft
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: valColor,
                      ),
                    ),
                  )
                : null,
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

// 🌐 دالة حساب الأيام المتبقية (خارج الكلاس كـ Top-level function وممتازة جداً)
String _calculateRemainingDays(String? deadlineStr) {
  if (deadlineStr == null || deadlineStr.isEmpty) return 'No deadline';

  try {
    DateTime? deadlineDate = DateTime.tryParse(deadlineStr);

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

    final differenceInDays = targetDate.difference(today).inDays;

    if (differenceInDays < 0) {
      return 'Expired';
    } else if (differenceInDays == 0) {
      return 'Today';
    } else if (differenceInDays == 1) {
      return 'Tomorrow';
    } else {
      return 'In $differenceInDays days';
    }
  } catch (e) {
    return 'Error';
  }
}
