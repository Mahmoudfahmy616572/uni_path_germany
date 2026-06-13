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
          'About the University',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          description ??
              "Detailed description about the university will be available soon.",
          style:  TextStyle(
            fontSize: 13.sp,
            color: const Color(0xFF475569),
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (description != null && description!.isNotEmpty) ...[
          SizedBox(height: 8.h),
          InkWell(
            onTap: () => _showFullDescription(context, description!),
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
      ],
    );
  }

  void _showFullDescription(BuildContext context, String desc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About the University'),
        content: SingleChildScrollView(
          child: Text(desc, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
