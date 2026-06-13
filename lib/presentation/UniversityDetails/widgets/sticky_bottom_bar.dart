import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/domain/entities/program_entity.dart';

import '../../../domain/entities/university_entity.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';

class StickyBottomBar extends StatelessWidget {
  final UniversityEntity university;
  final ProgramEntity programId;
  final bool initialSavedCheck;

  const StickyBottomBar({
    super.key,
    required this.university,
    required this.initialSavedCheck,
    required this.programId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          // Ø´Ø§Ø¯Ùˆ Ø®ÙÙŠÙ Ø¬Ø¯Ø§Ù‹ Ø¨ÙŠØ¯ÙŠ Ø¹Ù…Ù‚ Ù„ÙÙˆÙ‚
          BoxShadow(
            color: Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 1. Ø²Ø±Ø§Ø± Ø§Ù„Ù€ AI Ø§Ù„ØµØºÙŠØ± (Ù…Ø¸Ø¨ÙˆØ· ÙƒÙ€ Ù…Ø±Ø¨Ø¹ Ù†ÙØ³ Ø§Ù„ØµÙˆØ±Ø©)
            Container(
              height: 56.h, // Ù†ÙØ³ Ø§Ø±ØªÙØ§Ø¹ Ø§Ù„Ø²Ø±Ø§Ø± Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠ
              width: 56.w,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF), // Ø®Ù„ÙÙŠØ© ÙØ§ØªØ­Ø© Ø±Ø§ÙŠÙ‚Ø©
                borderRadius: BorderRadius.circular(16.r), // ÙƒÙŠØ±Ù Ù†Ø§Ø¹Ù…
              ),
              child: IconButton(
                icon: Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF4F46E5),
                  size: 26.sp,
                ),
                onPressed: () {
                  // Ø¶ÙŠÙ Ø§Ù„Ø£ÙƒØ´Ù† Ø¨ØªØ§Ø¹ Ø§Ù„Ù€ AI Ù‡Ù†Ø§
                },
              ),
            ),
            SizedBox(width: 16.w), // Ø§Ù„Ù…Ø³Ø§ÙØ© Ø¨ÙŠÙ† Ø§Ù„Ø²Ø±Ø§Ø±ÙŠÙ†
            // 2. Ø§Ù„Ø²Ø±Ø§Ø± Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠ (Add to Pipeline)
            Expanded(
              child:
                  BlocConsumer<UniversityDetailsCubit, UniversityDetailsState>(
                    listener: (context, state) {
                      // Ù„Ùˆ Ù…Ø­ØªØ§Ø¬ ØªØ¸Ù‡Ø± SnackBar Ù‡Ù†Ø§
                    },
                    builder: (context, state) {
                      bool isSaved = initialSavedCheck;
                      bool isLoading = false;

                      if (state is UniversitySaveStatus) {
                        isSaved = state.isSaved;
                        isLoading = state.isLoading;
                      }

                      return SizedBox(
                        height: 56.h, // Ø¹Ø´Ø§Ù† ÙŠÙƒÙˆÙ† Ù†ÙØ³ Ø§Ø±ØªÙØ§Ø¹ Ø²Ø±Ø§Ø± Ø§Ù„Ù€ AI
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => context
                                    .read<UniversityDetailsCubit>()
                                    .toggleSaveProgram(
                                      universityId: university.id,
                                      programId: programId.id,
                                      currentStatus: isSaved,
                                    ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaved
                                ? const Color(0xFF64748B) // Ù„Ùˆ Ù…Ø­ÙÙˆØ¸
                                : const Color(
                                    0xFF4F46E5,
                                  ), // Ø§Ù„Ù„ÙˆÙ† Ø§Ù„Ø£Ø³Ø§Ø³ÙŠ (Indigo)
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                16.r,
                              ), // Ù†ÙØ³ ÙƒÙŠØ±Ù Ø²Ø±Ø§Ø± Ø§Ù„Ù€ AI
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 24.w,
                                  height: 24.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  isSaved
                                      ? 'Saved (Remove)'
                                      : 'Add to Pipeline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
