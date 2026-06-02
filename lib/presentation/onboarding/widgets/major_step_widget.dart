import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_states.dart';

class MajorStepWidget extends StatelessWidget {
  final OnboardingCubit cubit;
  final OnboardingDataState state;

  const MajorStepWidget({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    // قائمة التخصصات الأساسية
    final List<String> majors = [
      'Engineering',
      'Computer Science & IT',
      'Business & Economics',
      'Medicine & Healthcare',
      'Natural Sciences',
      'Social Sciences & Humanities',
    ];

    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your major\nfield of study',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Choose the discipline that matches your academic background',
            style: TextStyle(color: AppColors.textGrey, fontSize: 15.sp),
          ),
          SizedBox(height: 32.h),

          Expanded(
            child: ListView.builder(
              itemCount: majors.length,
              itemBuilder: (context, index) {
                final majorName = majors[index];
                // 🎯 التعديل هنا: بنقارن مع fieldOfInterest اللي موجود في الـ State فعلياً
                final isSelected = state.fieldOfInterest == majorName;

                return GestureDetector(
                  onTap: () => cubit.updateField(
                    majorName,
                  ), // 🎯 استدعاء الميثود الصحيحة في الـ Cubit
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            majorName,
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16.sp,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 22,
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.textGrey.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
