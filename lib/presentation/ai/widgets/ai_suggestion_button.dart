import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiSuggestionButton extends StatelessWidget {
  final String label;
  final double? width;
  final VoidCallback onPressed;
  final int? remainingUses;

  const AiSuggestionButton({
    super.key,
    this.label = 'Improve with AI',
    this.width,
    required this.onPressed,
    this.remainingUses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width ?? double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(Icons.auto_awesome, size: 16.sp),
            label: Text(
              label,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (remainingUses != null && remainingUses! > 0)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              'Free AI uses remaining: $remainingUses/10',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[500],
              ),
            ),
          ),
      ],
    );
  }
}
