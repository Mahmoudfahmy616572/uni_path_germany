import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain/entities/university_entity.dart';

class DetailsHeader extends StatelessWidget {
  final UniversityEntity university;
  const DetailsHeader({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    final bool hasPrograms = university.programs.isNotEmpty;
    final firstProgram = hasPrograms ? university.programs.first : null;

    final String programName =
        firstProgram != null && firstProgram.programName.isNotEmpty
        ? firstProgram.programName
        : "Master's Program";

    final String degreeType =
        firstProgram != null && firstProgram.degreeType.isNotEmpty
        ? firstProgram.degreeType
        : "M.Sc.";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. حاوية اللوجو - محسّنة مع CachedNetworkImage
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildLogo(),
        ),
        SizedBox(width: 16.w),

        // 2. اسم الجامعة والبرنامج المستهدف
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                university.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                degreeType,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                programName,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (university.location != null) ...[
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      university.location!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 8.w),

        // 3. دائرة الـ Match Percentage
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50.w,
              height: 50.h,
              child: CircularProgressIndicator(
                value: university.matchPercentage / 100,
                backgroundColor: const Color(0xFFDCFCE7),
                color: const Color(0xFF10B981),
                strokeWidth: 4,
              ),
            ),
            Text(
              '${university.matchPercentage}%',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF15803D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogo() {
    final String logoUrl = university.logoUrl ?? '';
    final String fallbackText = university.logoText.isNotEmpty
        ? university.logoText
        : 'UNI';

    if (logoUrl.isEmpty) {
      return _buildFallbackLogo(fallbackText);
    }

    return CachedNetworkImage(
      imageUrl: logoUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallbackLogo(fallbackText),
    );
  }

  Widget _buildFallbackLogo(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF4F46E5),
        ),
      ),
    );
  }
}
