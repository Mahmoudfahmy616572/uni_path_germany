import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../cubit/university_search_cubit.dart';

class AdvancedFilterPanel extends StatelessWidget {
  final bool requiresIelts;
  final bool acceptsMoi; // 🔥
  final double maxTuition;
  final String selectedLanguage;

  const AdvancedFilterPanel({
    super.key,
    required this.requiresIelts,
    required this.acceptsMoi, // 🔥
    required this.maxTuition,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 الـ الـ Row الجديد فوق خالص: كلمة Filter و Clear All بالملي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: const Color(0xFF1E293B),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      fontSize: 15.sp,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // استدعاء دالة المسح الشامل للفلاتر
                  context.read<UniversitySearchCubit>().clearAllFilters();
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1), // اللون البنفسجي الرايق للتفاعل
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),

          // 1. زرار الـ IELTS التفاعلي
          _buildToggleRow(
            title: 'IELTS Required',
            subtitle: 'Show programs requiring English test',
            value: requiresIelts,
            onToggle: () {
              context.read<UniversitySearchCubit>().updateFilters(
                requiresIelts: !requiresIelts,
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),

          // 🔥 2. زرار الـ MOI التفاعلي الجديد (بالملي زي الآيلتس)
          _buildToggleRow(
            title: 'MOI Accepted',
            subtitle: 'Medium of Instruction certificate support',
            value: acceptsMoi,
            onToggle: () {
              context.read<UniversitySearchCubit>().updateFilters(
                acceptsMoi: !acceptsMoi,
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),

          // 3. الـ Slider الحركي للـ Max Tuition Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Max Tuition / Year',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontSize: 14.sp,
                ),
              ),
              Text(
                '€${maxTuition.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF6366F1),
              trackHeight: 4,
            ),
            child: Slider(
              min: 0,
              max: 20000,
              divisions: 20,
              value: maxTuition,
              onChanged: (val) {
                context.read<UniversitySearchCubit>().updateFilters(
                  maxTuition: val,
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),

          // 4. اختيار لغة الدراسة (English / German)
          Text(
            'Instruction Language',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: ['All', 'English', 'German'].map((lang) {
              final isSelected = selectedLanguage == lang;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<UniversitySearchCubit>().updateFilters(
                      language: lang,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        lang,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ويدجت مساعدة مخصصة وموحدة للأزرار التفاعلية (IELTS & MOI) لتوفير الكود ومنع التكرار
  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.sp),
            ),
          ],
        ),
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100.r),
              color: value ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
