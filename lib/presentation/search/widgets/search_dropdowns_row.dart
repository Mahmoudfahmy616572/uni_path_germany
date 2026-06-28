import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../cubit/university_search_cubit.dart';

class SearchDropdownsRow extends StatelessWidget {
  final String currentIntake;
  final String currentDegree;
  final String currentMajor;
  final List<String> availableDegrees;
  final List<String> availableMajors;

  const SearchDropdownsRow({
    super.key,
    required this.currentIntake,
    required this.currentDegree,
    required this.currentMajor,
    required this.availableDegrees,
    required this.availableMajors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownContainer(context,
            child: DropdownButton<String>(
              value: ['All', 'Winter Semester', 'Summer Semester', 'Both Semesters'].contains(currentIntake) ? currentIntake : 'All',
              isExpanded: true,
              underline: const SizedBox(),
              items: ['All', 'Winter Semester', 'Summer Semester', 'Both Semesters'].map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val == 'All' ? '📅 Intake' : val,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: context.isDark ? AppColors.textMain : null,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => context
                  .read<UniversitySearchCubit>()
                  .updateFilters(intake: value),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildDropdownContainer(context,
            child: availableDegrees.isEmpty
                ? Center(child: SizedBox(width: 14.w, height: 14.w, child: CircularProgressIndicator(strokeWidth: 2.w)))
                : DropdownButton<String>(
              value: availableDegrees.contains(currentDegree) ? currentDegree : 'All',
              isExpanded: true,
              underline: const SizedBox(),
              items: ['All', ...availableDegrees].map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val == 'All' ? '🎓 Degree' : val,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      color: context.isDark ? AppColors.textMain : null,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => context
                  .read<UniversitySearchCubit>()
                  .updateFilters(degree: value),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildDropdownContainer(context,
            child: availableMajors.isEmpty
                ? Center(child: SizedBox(width: 14.w, height: 14.w, child: CircularProgressIndicator(strokeWidth: 2.w)))
                : DropdownButton<String>(
              value: availableMajors.contains(currentMajor) ? currentMajor : 'All',
              isExpanded: true,
              underline: const SizedBox(),
              items: ['All', ...availableMajors].map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val == 'All' ? '🔬 Major' : val,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      color: context.isDark ? AppColors.textMain : null,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => context
                  .read<UniversitySearchCubit>()
                  .updateFilters(major: value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer(BuildContext context, {required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      height: 40.h,
      child: Center(child: child),
    );
  }
}
