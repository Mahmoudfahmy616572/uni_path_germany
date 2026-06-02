import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PipelineFilterBar extends StatelessWidget {
  final String activeFilter;
  final Map<String, int> statusCounts;
  final Function(String) onFilterSelected;

  const PipelineFilterBar({
    super.key,
    required this.activeFilter,
    required this.statusCounts,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'saved', 'label': 'Saved'},
      {'key': 'preparing', 'label': 'Preparing'},
      {'key': 'applied', 'label': 'Applied'},
      {'key': 'waiting', 'label': 'Waiting'},
      {'key': 'accepted', 'label': 'Accepted'},
    ];

    return Container(
      height: 56,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = activeFilter == filter['key'];
          final count = statusCounts[filter['key']] ?? 0;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${filter['label']} $count'),
              selected: isSelected,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 13.sp,

                fontWeight: FontWeight.w600,
              ),
              selectedColor: const Color(
                0xFF4F46E5,
              ), // البنفسجي الأنيق من الاسكرينة الجديدة
              backgroundColor: const Color(0xFFF1F5F9),
              onSelected: (_) => onFilterSelected(filter['key']!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              showCheckmark: false,
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }
}
