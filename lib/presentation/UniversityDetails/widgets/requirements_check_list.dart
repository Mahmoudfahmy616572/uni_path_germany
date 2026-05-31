import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/university_model.dart';
import '../cubit/university_details_cubit.dart';

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
              const SizedBox(width: 12),
              Text(
                item['title'] as String,
                style: TextStyle(
                  fontSize: 14,
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
                  fontSize: 11,
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
