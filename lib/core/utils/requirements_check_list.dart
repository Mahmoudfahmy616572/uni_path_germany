import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../localization/app_localizations.dart';
import '../../domain/entities/university_entity.dart';
import '../../presentation/UniversityDetails/cubit/university_details_cubit.dart';
import '../../presentation/UniversityDetails/cubit/university_details_state.dart';
import 'custom_snack_bar.dart';

class _ChecklistItem {
  final String title;
  final String column;
  final dynamic value;

  const _ChecklistItem({
    required this.title,
    required this.column,
    required this.value,
  });
}

class RequirementsChecklistList extends StatelessWidget {
  final UniversityEntity university;
  const RequirementsChecklistList({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UniversityDetailsCubit, UniversityDetailsState>(
      listenWhen: (previous, current) =>
          current is UniversitySaveStatus &&
          current.errorMessage != null &&
          previous is UniversitySaveStatus &&
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state is UniversitySaveStatus && state.errorMessage != null) {
          final msg = state.errorMessage!;
          String userMessage;
          if (msg.contains('Timeout') || msg.contains('timed out')) {
            userMessage = 'Upload timed out. Please check your connection and try again.';
          } else if (msg.contains('StorageException') || msg.contains('storage')) {
            userMessage = 'Upload failed. The server may be unavailable. Please try again later.';
          } else if (msg.contains('429') || msg.contains('rate limit')) {
            userMessage = 'Too many requests. Please wait a moment and try again.';
          } else {
            userMessage = 'Upload failed. Please try again.';
          }
          CustomSnackBar.show(context, message: userMessage, isError: true);
        }
      },
      builder: (context, state) {
        // 🎯 المزامنة العالمية: نأخذ نسخة الجامعة من الـ State لأن الكيوبيت قام بمزامنتها مع البروفايل
        final uni =
            (state is UniversitySaveStatus && state.currentUniversity != null)
            ? state.currentUniversity!
            : university;

        final t = AppLocalizations.of(context).translate;
        final items = [
          _ChecklistItem(
            title: t('academicTranscripts'),
            column: 'has_transcripts',
            value: uni.hasTranscripts,
          ),
          _ChecklistItem(
            title: t('bachelorCertificate'),
            column: 'has_bachelor_cert',
            value: uni.hasBachelorCert,
          ),
          _ChecklistItem(
            title: t('sopMotivationLetter'),
            column: 'has_sop',
            value: uni.hasSop,
          ),
          _ChecklistItem(
            title: t('cvResume'),
            column: 'has_cv',
            value: uni.hasCv,
          ),
          _ChecklistItem(
            title: t('languageCertOptional'),
            column: 'has_language_cert',
            value: uni.hasLanguageCert,
          ),
        ];

        return Column(
          children: items.map((item) {
            final String valStr = item.value?.toString() ?? '';
            final bool isUploaded = valStr.startsWith('http');
            final String colName = item.column;

            double? progress;
            if (state is UniversitySaveStatus) {
              progress = state.fileUploadProgress[colName];
            }

            final bool isOptional = item.column == 'has_language_cert';
        return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isUploaded
                      ? const Color(0xFFBBF7D0)
                      : isOptional
                          ? const Color(0xFFE2E8F0)
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
                          item.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isUploaded
                                ? const Color(0xFF166534)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isUploaded)
                          Text(
                            "Document synced from profile ✅",
                            style: TextStyle(
                              fontSize: 10.sp,
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
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).translate('uploadDocumentTitle'),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
                title: Text(AppLocalizations.of(context).translate('pdfFile')),
                subtitle: Text(AppLocalizations.of(context).translate('pdfSubtitle')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null && result.files.single.path != null && context.mounted) {
                    final filePath = result.files.single.path!;
                    final pickedFile = result.files.single;
                    if (pickedFile.size > 20 * 1024 * 1024) {
                      if (context.mounted) {
                        CustomSnackBar.show(context, message: AppLocalizations.of(context).translate('fileTooLarge'), isError: true);
                      }
                      return;
                    }
                    context.read<UniversityDetailsCubit>().uploadApplicationFile(
                      universityId: uniId,
                      columnName: col,
                      file: File(filePath),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
