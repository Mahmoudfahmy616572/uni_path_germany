import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UniversityStatsSection extends StatelessWidget {
  final String uniName;
  final int? qsRanking;

  const UniversityStatsSection({
    super.key,
    required this.uniName,
    this.qsRanking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About the University',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$uniName is one of Europe\'s leading research universities.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    'QS Ranking',
                    style: TextStyle(fontSize: 10.sp, color: Color(0xFF64748B)),
                  ),
                  Text(
                    qsRanking != null && qsRanking! > 0
                        ? '= $qsRanking'
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Divider(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.star_border, '4.6/5', 'Reviews'),
              _buildStatItem(Icons.people_outline, '40k+', 'Students'),
              _buildStatItem(Icons.work_outline, '95%', 'Employment'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: const Color(0xFF64748B)),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }
}
