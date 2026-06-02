import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/university_model.dart';

class PipelineUniversityCard extends StatelessWidget {
  final UniversityModel app;
  final VoidCallback onTap;

  const PipelineUniversityCard({
    super.key,
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // حسبة الـ Progress
    int docsCount = [
      app.hasTranscripts,
      app.hasCv,
      app.hasSop,
      app.hasBachelorCert,
    ].where((c) => c).length;
    double progress = docsCount / 4;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // السطر العلوي: اللوجو والاسم والنسبة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      app.logoText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: TextStyle(
                            fontSize: 15.sp,

                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          app.program,
                          style: TextStyle(
                            fontSize: 13.sp,

                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildMatchBadge(app.matchPercentage),
                ],
              ),
              SizedBox(height: 16.h),

              // الـ Deadlines والـ Missing Docs سريعا
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaInfo(
                    Icons.calendar_today,
                    '15 Jul 2026',
                    'In 18 days',
                    Colors.red,
                  ),
                  _buildMetaInfo(
                    Icons.assignment_outlined,
                    'Missing',
                    app.hasBachelorCert ? 'None' : 'Bachelor Certificate',
                    const Color(0xFF4F46E5),
                  ),
                  _buildMetaInfo(
                    Icons.trending_up,
                    'Chance',
                    'High',
                    const Color(0xFF10B981),
                  ),
                ],
              ),

              // الـ AI Recommendation Banner الذكي
              if (!app.hasSop) ...[
                SizedBox(height: 12.h),
                _buildAiSuggestionBanner(
                  "Improving your SOP could increase your chances by 10%.",
                ),
              ],

              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // أزرار التحكم السفلية للكارد
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                      onPressed: () {}, // Ask AI Button
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge(int match) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            value: match / 100,
            backgroundColor: const Color(0xFFF1F5F9),
            color: const Color(0xFF10B981),
            strokeWidth: 4,
          ),
        ),
        Text(
          '$match%',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaInfo(IconData icon, String title, String sub, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            SizedBox(width: 4.w),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: Text(
            sub,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestionBanner(String text) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4F46E5)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Color(0xFF4F46E5),
          ),
        ],
      ),
    );
  }
}
