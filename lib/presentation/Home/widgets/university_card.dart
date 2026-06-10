import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/university_entity.dart';

class UniversityCard extends StatelessWidget {
  final UniversityEntity university;
  const UniversityCard({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    final int recommendedCount = university.programs
        .where((p) => p.isRecommended)
        .length;
    final firstProg = university.programs.isNotEmpty
        ? university.programs.first
        : null;

    return InkWell(
      onTap: () => context.push('/university_details', extra: university),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
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
            // 🎯 اللوجو الحقيقي مع Fallback
            _buildLogo(),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          university.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                      ),
                      Text(
                        "${university.matchPercentage}% Match",
                        style: GoogleFonts.poppins(
                          color: university.matchPercentage >= 70
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: recommendedCount > 0
                            ? const Color(0xFFF5A67D)
                            : Colors.grey.shade400,
                        size: 16.r,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          "$recommendedCount Programs Match Your Profile",
                          style: GoogleFonts.poppins(
                            color: recommendedCount > 0
                                ? const Color(0xFF4F46E5)
                                : Colors.grey.shade600,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      if (firstProg != null) ...[
                        _buildTag(firstProg.intakeType),
                        _buildTag(firstProg.degreeType),
                        _buildTag(firstProg.instructionLanguage),
                      ],
                      _buildTag("Germany 🇩🇪"),
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

  Widget _buildLogo() {
    final String logoUrl = university.logoUrl ?? '';
    final String fallbackText = university.logoText.isNotEmpty
        ? university.logoText
        : 'UNI';

    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) =>
                  _buildFallbackLogo(fallbackText),
            )
          : _buildFallbackLogo(fallbackText),
    );
  }

  Widget _buildFallbackLogo(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: const Color(0xFF4F46E5),
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
