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
    // Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„ØªØ®ØµØµØ§Øª Ø§Ù„Ø£Ø³Ø§Ø³ÙŠØ©
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
                // ðŸŽ¯ Ø§Ù„ØªØ¹Ø¯ÙŠÙ„ Ù‡Ù†Ø§: Ø¨Ù†Ù‚Ø§Ø±Ù† Ù…Ø¹ fieldOfInterest Ø§Ù„Ù„ÙŠ Ù…ÙˆØ¬ÙˆØ¯ ÙÙŠ Ø§Ù„Ù€ State ÙØ¹Ù„ÙŠØ§Ù‹
                final isSelected = state.fieldOfInterest == majorName;

                return GestureDetector(
                  onTap: () => cubit.updateField(
                    majorName,
                  ), // ðŸŽ¯ Ø§Ø³ØªØ¯Ø¹Ø§Ø¡ Ø§Ù„Ù…ÙŠØ«ÙˆØ¯ Ø§Ù„ØµØ­ÙŠØ­Ø© ÙÙŠ Ø§Ù„Ù€ Cubit
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
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
                                color: AppColors.textGrey.withValues(alpha: 0.4),
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
