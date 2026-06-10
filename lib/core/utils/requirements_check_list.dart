import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/university_entity.dart';
import '../../presentation/UniversityDetails/cubit/university_details_cubit.dart';
import '../../presentation/UniversityDetails/cubit/university_details_state.dart';

class RequirementsChecklistList extends StatelessWidget {
  final UniversityEntity university;
  const RequirementsChecklistList({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityDetailsCubit, UniversityDetailsState>(
      builder: (context, state) {
        // 🎯 المزامنة العالمية: نأخذ نسخة الجامعة من الـ State لأن الكيوبيت قام بمزامنتها مع البروفايل
        final uni =
            (state is UniversitySaveStatus && state.currentUniversity != null)
            ? state.currentUniversity!
            : university;

        final items = [
          {
            'title': 'Academic Transcripts',
            'col': 'has_transcripts',
            'value': uni.hasTranscripts,
          },
          {
            'title': 'Bachelor Certificate',
            'col': 'has_bachelor_cert',
            'value': uni.hasBachelorCert,
          },
          {
            'title': 'SOP / Motivation Letter',
            'col': 'has_sop',
            'value': uni.hasSop,
          },
          {'title': 'CV / Resume', 'col': 'has_cv', 'value': uni.hasCv},
        ];

        return Column(
          children: items.map((item) {
            final String valStr = item['value']?.toString() ?? '';
            final bool isUploaded = valStr.startsWith('http');
            final String colName = item['col'] as String;

            double? progress;
            if (state is UniversitySaveStatus) {
              progress = state.fileUploadProgress[colName];
            }

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isUploaded
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isUploaded
                        ? Icons.check_circle
                        : Icons.cloud_upload_outlined,
                    color: isUploaded
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isUploaded
                                ? const Color(0xFF166534)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isUploaded)
                          const Text(
                            "Document synced from profile ✅",
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF10B981),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusArea(
                    context,
                    colName,
                    isUploaded,
                    uni.id,
                    progress,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatusArea(
    BuildContext context,
    String colName,
    bool isUploaded,
    String uniId,
    double? progress,
  ) {
    if (progress != null) {
      return Column(
        children: [
          SizedBox(
            width: 70.w,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF4F46E5),
              minHeight: 6.h,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "${(progress * 100).toInt()}%",
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4F46E5),
            ),
          ),
        ],
      );
    }

    if (isUploaded) {
      return TextButton(
        onPressed: () => _handlePick(context, uniId, colName),
        child: Text(
          "Replace",
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _handlePick(context, uniId, colName),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEEF2FF),
        foregroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      child: Text(
        "Upload",
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _handlePick(
    BuildContext context,
    String uniId,
    String col,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      if (context.mounted) {
        context.read<UniversityDetailsCubit>().uploadApplicationFile(
          universityId: uniId,
          columnName: col,
          file: File(result.files.single.path!),
        );
      }
    }
  }
}
