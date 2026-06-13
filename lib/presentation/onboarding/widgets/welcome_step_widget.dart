import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';

class WelcomeStepWidget extends StatelessWidget {
  const WelcomeStepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:  Center(
              child: Text('ðŸŽ“', style: TextStyle(fontSize: 80.sp)),
            ),
          ),
          SizedBox(height: 40.h),
          RichText(
            textAlign: TextAlign.center,
            text:  TextSpan(
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: 'Let\'s personalize\n',
                  style: TextStyle(color: AppColors.textDark),
                ),
                TextSpan(
                  text: 'your experience',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
           Text(
            'We\'ll ask you a few questions to find the best universities and programs for you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 16.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
