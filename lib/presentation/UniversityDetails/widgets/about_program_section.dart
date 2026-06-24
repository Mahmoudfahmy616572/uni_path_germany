import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';

class AboutProgramSection extends StatelessWidget {
  final String? description;
  const AboutProgramSection({super.key, this.description});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          loc.translate('aboutUniversity'),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          description ??
              loc.translate('descriptionPlaceholder'),
          style:  TextStyle(
            fontSize: 13.sp,
            color: context.isDark ? AppColors.textMuted : const Color(0xFF475569),
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
              children: [
                Text(
                  loc.translate('readMore'),
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF4F46E5),
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showFullDescription(BuildContext context, String desc) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('aboutUniversity')),
        content: SingleChildScrollView(
          child: Text(desc, style: TextStyle(fontSize: 14.sp, height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('close')),
          ),
        ],
      ),
    );
  }
}
