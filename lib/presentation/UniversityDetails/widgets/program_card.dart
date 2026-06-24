// ====================
// FILE: lib/presentation/UniversityDetails/widgets/program_card.dart
// ====================
//
// التغيير الوحيد على الكود الأصلي:
//  ✅ استبدلنا الـ Row اللي كان بيعرض "% match for your profile"
//     بالـ ProgramScoreBadge الجديد اللي فيه الـ expandable breakdown

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'breack_down_widget.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/webview_screen.dart';
import '../../../domain/entities/program_entity.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';

class ProgramCard extends StatelessWidget {
  final ProgramEntity program;
  final String universityId;

  const ProgramCard({
    super.key,
    required this.program,
    required this.universityId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityDetailsCubit, UniversityDetailsState>(
      builder: (context, state) {
        bool isSaved = false;
        if (state is UniversitySaveStatus) {
          isSaved = state.savedProgramIds.contains(program.id);
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: program.isRecommended
                  ? const Color(0xFF22C55E)
                  : (context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              width: program.isRecommended ? 1.5.w : 1.w,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Program Name
                        Text(
                          program.programName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 6.h),

                        // ✅ الـ ProgramScoreBadge بدل الـ Row القديم
                        // الـ badge قابل للضغط ويعرض الـ breakdown expandable
                        ProgramScoreBadge(program: program),
                      ],
                    ),
                  ),

                  // Bookmark Button
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? const Color(0xFF4F46E5) : Colors.grey,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.read<UniversityDetailsCubit>().toggleSaveProgram(
                        universityId: universityId,
                        programId: program.id,
                        currentStatus: isSaved,
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Degree + Intake badges
              Row(
                children: [
                  _buildBadge(context, Icons.school_outlined, program.degreeType),
                  SizedBox(width: 8.w),
                  _buildBadge(context,
                    Icons.calendar_today_outlined,
                    program.intakeType,
                  ),
                  const Spacer(),
                  if (program.isRecommended)
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFEAB308),
                      size: 20,
                    ),
                ],
              ),

              if (program.programUrl != null && program.programUrl!.isNotEmpty) ...[
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WebViewScreen(
                            url: program.programUrl!,
                            title: program.programName,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.open_in_new, size: 15.sp),
                    label: Text('View Program Website',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String text) {
    final displayText = text.length > 12 ? '${text.substring(0, 12)}...' : text;
    return Container(
      constraints: BoxConstraints(maxWidth: 140.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              displayText,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}
