import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../cubit/university_search_cubit.dart';

class SearchDropdownsRow extends StatelessWidget {
  final String currentIntake;
  final String currentDegree;
  final String currentMajor;

  const SearchDropdownsRow({
    super.key,
    required this.currentIntake,
    required this.currentDegree,
    required this.currentMajor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 🎯 دروب داون الفصل الدراسي (Winter/Summer/Both)
        Expanded(
          child: _buildDropdownContainer(
            child: DropdownButton<String>(
              value:
                  [
                    'All',
                    'Winter Semester',
                    'Summer Semester',
                    'Both Semesters',
                  ].contains(currentIntake)
                  ? currentIntake
                  : 'All',
              isExpanded: true,
              underline: const SizedBox(),
              items:
                  [
                    'All',
                    'Winter Semester',
                    'Summer Semester',
                    'Both Semesters',
                  ].map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(
                        val == 'All' ? '📅 Intake' : val,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
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
        // دروب داون الدرجة العلمية
        Expanded(
          child: _buildDropdownContainer(
            child: DropdownButton<String>(
              value: currentDegree,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['All', 'Bachelor', 'Master', 'PhD'].map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val == 'All' ? '🎓 Degree' : val,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
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
        // دروب داون التخصص
        Expanded(
          child: _buildDropdownContainer(
            child: DropdownButton<String>(
              value: currentMajor,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['All', 'Computer Science', 'Medicine', 'Engineering'].map(
                (String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(
                      val == 'All' ? '🔬 Major' : val,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) => context
                  .read<UniversitySearchCubit>()
                  .updateFilters(major: value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      height: 40,
      child: Center(child: child),
    );
  }
}
