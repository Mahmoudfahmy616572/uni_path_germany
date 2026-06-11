import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // مهم جداً عشان الـ HapticFeedback
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. الـ Container الخارجي بقى وظيفته بس يعمل الـ Shadow
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // 2. الـ Material هو اللي بياخد اللون والشكل الدائري
          child: Material(
            color: Colors.white,
            shape: CircleBorder(side: BorderSide(color: Colors.grey.shade200)),
            clipBehavior:
                Clip.antiAlias, // بيقص الموجة عشان ماتخرجش برا الدايرة
            child: InkWell(
              onTap: () {
                // إضافة هزة خفيفة للموبايل مع الضغطة
                HapticFeedback.lightImpact();
                onTap();
              },
              splashColor: const Color(
                0xFF5A67D8,
              ).withValues(alpha: 0.2), // لون الموجة
              highlightColor: const Color(
                0xFF5A67D8,
              ).withValues(alpha: 0.1), // لون الهالة وقت اللمس
              child: SizedBox(
                width: 60,
                height: 60,
                child: Icon(icon, color: const Color(0xFF5A67D8), size: 24),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: const Color(0xFF1A202C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
