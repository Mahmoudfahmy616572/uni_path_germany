import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/university_model.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';

class StickyBottomBar extends StatelessWidget {
  final UniversityModel university;
  final bool initialSavedCheck;

  const StickyBottomBar({
    super.key,
    required this.university,
    required this.initialSavedCheck,
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
          // شادو خفيف جداً بيدي عمق لفوق
          BoxShadow(
            color: Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 10.r,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 1. زرار الـ AI الصغير (مظبوط كـ مربع نفس الصورة)
            Container(
              height: 56.h, // نفس ارتفاع الزرار الرئيسي
              width: 56.w,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF), // خلفية فاتحة رايقة
                borderRadius: BorderRadius.circular(16.r), // كيرف ناعم
              ),
              child: IconButton(
                icon: Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF4F46E5),
                  size: 26.sp,
                ),
                onPressed: () {
                  // ضيف الأكشن بتاع الـ AI هنا
                },
              ),
            ),
            SizedBox(width: 16.w), // المسافة بين الزرارين
            // 2. الزرار الرئيسي (Add to Pipeline)
            Expanded(
              child:
                  BlocConsumer<UniversityDetailsCubit, UniversityDetailsState>(
                    listener: (context, state) {
                      // لو محتاج تظهر SnackBar هنا
                    },
                    builder: (context, state) {
                      bool isSaved = initialSavedCheck;
                      bool isLoading = false;

                      if (state is UniversitySaveStatus) {
                        isSaved = state.isSaved;
                        isLoading = state.isLoading;
                      }

                      return SizedBox(
                        height: 56.h, // عشان يكون نفس ارتفاع زرار الـ AI
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => context
                                    .read<UniversityDetailsCubit>()
                                    .toggleSaveUniversity(
                                      university.id,
                                      isSaved,
                                    ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaved
                                ? const Color(0xFF64748B) // لو محفوظ
                                : const Color(
                                    0xFF4F46E5,
                                  ), // اللون الأساسي (Indigo)
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                16.r,
                              ), // نفس كيرف زرار الـ AI
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ?  SizedBox(
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
