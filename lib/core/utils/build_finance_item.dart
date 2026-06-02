import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

Widget buildFinanceItem(
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
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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

String calculateRemainingDays(String? deadlineStr) {
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
      deadlineDate!.year,
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
