import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/university_entity.dart';
import '../cubit/home_cubit.dart';

class UniversityCard extends StatelessWidget {
  // 🎯 بنستقبل الـ Entity كاملة هنا عشان نقرأ منها كل الداتا
  final UniversityEntity university;

  const UniversityCard({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await context.push('/university_details', extra: university);
        if (context.mounted) {
          context.read<HomeCubit>().calculateAndFetchRecommendations(
            forceRefresh: true,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // University Logo Placeholder
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  university.logoText, // 👈 بنجيبها من الـ object
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF5A67D8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // University Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          university.name, // 👈 بنجيبها من الـ object
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,

                            color: const Color(0xFF1A202C),
                          ),
                        ),
                      ),
                      Text(
                        "${university.matchPercentage}% Match", // 👈 بنجيبها من الـ object
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    university.program, // 👈 بنجيبها من الـ object
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Tags
                  Row(
                    children: [
                      // 🔥 حركة ذكية: الـ Tag بيظهر ديناميكياً بناءً على شروط الجامعة الحقيقية
                      _buildTag(
                        university.requiresIelts
                            ? "IELTS Required"
                            : "No IELTS",
                      ),
                      SizedBox(width: 8.w),
                      _buildTag("English Program"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          color: const Color(0xFF5A67D8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
