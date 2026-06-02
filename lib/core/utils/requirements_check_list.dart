import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/university_model.dart';
import '../../presentation/UniversityDetails/cubit/university_details_cubit.dart';

class RequirementsChecklistList extends StatelessWidget {
  final UniversityModel university;
  const RequirementsChecklistList({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    // مصفوفة العناصر للـ Checklist
    final items = [
      {
        'title': 'Academic Transcripts',
        'value': university.hasTranscripts,
        'col': 'has_transcripts',
      },
      {
        'title': 'Bachelor Certificate',
        'value': university.hasBachelorCert,
        'col': 'has_bachelor_cert',
      }, // فرضاً أنها مرفوعة دايما كمثال
      {
        'title': 'SOP / Motivation Letter',
        'value': university.hasSop,
        'col': 'has_sop',
      },
      {'title': 'CV / Resume', 'value': university.hasCv, 'col': 'has_cv'},
    ];

    return Column(
      children: items.map((item) {
        bool isDone = item['value'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  context.read<UniversityDetailsCubit>().updateChecklistItem(
                    universityId: university.id,
                    column: item['col'] as String,
                    newValue: !isDone,
                  );
                },
                child: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : const Color(0xFFCBD5E1),
                  size: 22,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                item['title'] as String,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDone
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Text(
                isDone ? 'Completed' : 'Missing',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
