import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';

class DescriptionSection extends StatelessWidget {
  final String? description;
  const DescriptionSection({super.key, this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('aboutProgram'),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            description ??
                AppLocalizations.of(context).translate('noDescriptionAvailable'),
            style: TextStyle(
              fontSize: 13.sp,
              color: Color(0xFF334155),
              height: 1.5.h,
            ),
          ),
        ),
      ],
    );
  }
}
