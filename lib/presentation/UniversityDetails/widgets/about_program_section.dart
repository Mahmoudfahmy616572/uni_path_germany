import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutProgramSection extends StatelessWidget {
  final String? description;
  const AboutProgramSection({super.key, this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          'About the Program',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          description ??
              "Detailed description about the program will be available soon. It covers core modules, career prospects, and academic requirements.",
          style:  TextStyle(
            fontSize: 13.sp,
            color: Color(0xFF475569),
            height: 1.5,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () {},
          child: Row(
            children: const [
              Text(
                "Read more",
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF4F46E5),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
