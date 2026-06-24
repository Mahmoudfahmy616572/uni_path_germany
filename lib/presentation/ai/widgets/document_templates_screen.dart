import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';

class DocumentTemplatesScreen extends StatelessWidget {
  const DocumentTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Document Templates'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.h),
          child: Container(color: AppColors.primary.withValues(alpha: 0.2), height: 2.h),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          _buildTemplateCard(
            context,
            icon: Icons.description_outlined,
            title: 'CV / Resume - German Style',
            subtitle: 'Tabular format preferred by German universities',
            sections: [
              'Personal Information (Name, Address, Phone, Email)',
              'Education (reverse chronological order)',
              'Work Experience (if any)',
              'Skills & Languages',
              'Interests & Activities',
              'References (optional)',
            ],
            tip: 'Keep it concise — max 2 pages. Use Europass format or tabular CV.',
            color: const Color(0xFF6366F1),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildTemplateCard(
            context,
            icon: Icons.article_outlined,
            title: 'Motivation Letter (Statement of Purpose)',
            subtitle: 'Academic-focused letter for German universities',
            sections: [
              'Header: Your contact + University address + Date',
              'Subject: "Motivation Letter for [Program Name]"',
              'Paragraph 1: Introduce yourself + what you are applying for',
              'Paragraph 2: Why this program? Connect your background to the program',
              'Paragraph 3: Why Germany? Show knowledge of the education system',
              'Paragraph 4: Your future goals — how this degree fits your career plans',
              'Closing: Confident closing + signature',
            ],
            tip: 'Be specific about the university and program. Generic letters are easily spotted.',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildTemplateCard(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Letter of Recommendation Request',
            subtitle: 'Professional email to ask professors for recommendation',
            sections: [
              'Subject: "Recommendation Letter Request — [Your Name]"',
              'Greeting: Dear Professor [Name],',
              'Introduction: Remind them who you are (course, semester)',
              'Request: Politely ask if they would write a recommendation',
              'Details: Attach your CV, grades, and program list',
              'Deadline: Mention when you need it',
              'Closing: Thank them + offer to meet in person',
            ],
            tip: 'Ask at least 4 weeks before the deadline. Provide all materials upfront.',
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildTipCard(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> sections,
    required String tip,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textMain : const Color(0xFF1E293B),
                          )),
                      SizedBox(height: 4.h),
                      Text(subtitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sections
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sections.asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark ? AppColors.textMain : const Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                Divider(height: 24.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Pro Tip',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Use our AI Document Generator to create a personalized CV or Motivation Letter based on your profile. Go to any university detail page and tap "Generate CV" or "Generate Motivation Letter".',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? AppColors.textMuted : const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
