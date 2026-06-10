// ====================
// FILE: lib/presentation/UniversityDetails/widgets/program_card.dart
// ====================
//
// التغيير الوحيد على الكود الأصلي:
//  ✅ استبدلنا الـ Row اللي كان بيعرض "% match for your profile"
//     بالـ ProgramScoreBadge الجديد اللي فيه الـ expandable breakdown

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'breack_down_widget.dart';
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: program.isRecommended
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFE2E8F0),
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
                  _buildBadge(Icons.school_outlined, program.degreeType),
                  SizedBox(width: 8.w),
                  _buildBadge(
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: const Color(0xFF64748B)),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
