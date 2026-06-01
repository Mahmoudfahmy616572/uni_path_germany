import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/university_search_cubit.dart';

class SearchDropdownsRow extends StatelessWidget {
  final String currentCountry;
  final String currentDegree;
  final String currentMajor;

  const SearchDropdownsRow({
    super.key,
    required this.currentCountry,
    required this.currentDegree,
    required this.currentMajor,
  });

  // خريطة الأعلام السبعة بالملي المتاحة عندك في السيستم
  String _getFlag(String country) {
    switch (country.toLowerCase()) {
      case 'germany':
        return '🇩🇪';
      case 'netherlands':
        return '🇳🇱';
      case 'united kingdom':
      case 'uk':
        return '🇬🇧';
      case 'usa':
        return '🇺🇸';
      case 'canada':
        return '🇨🇦';
      case 'italy':
        return '🇮🇹';
      case 'spain':
        return '🇪🇸';
      default:
        return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. دروب داون الدول بالأعلام
        Expanded(
          child: _buildDropdownContainer(
            child: DropdownButton<String>(
              value: currentCountry,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF64748B),
                size: 20,
              ),
              items:
                  [
                    'All',
                    'Germany',
                    'Netherlands',
                    'UK',
                    'USA',
                    'Canada',
                    'Italy',
                    'Spain',
                  ].map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(
                        val == 'All' ? '🌍 Country' : '${_getFlag(val)} $val',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                context.read<UniversitySearchCubit>().updateFilters(
                  country: value,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 2. دروب داون الدرجة العلمية
        Expanded(
          child: _buildDropdownContainer(
            child: DropdownButton<String>(
              value: currentDegree,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF64748B),
                size: 20,
              ),
              items: ['All', 'Bachelor', 'Master', 'PhD'].map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val == 'All' ? '🎓 Degree' : val,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                context.read<UniversitySearchCubit>().updateFilters(
                  degree: value,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 3. دروب داون التخصصات
        Expanded(
          child: _buildDropdownContainer(
            child: DropdownButton<String>(
              value: currentMajor,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF64748B),
                size: 20,
              ),
              items:
                  [
                    'All',
                    'Computer Science',
                    'Medicine',
                    'Data Science',
                    'Biology',
                  ].map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(
                        val == 'All' ? '🔬 Major' : val,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                context.read<UniversitySearchCubit>().updateFilters(
                  major: value,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      height: 40,
      child: Center(child: child),
    );
  }
}
