import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/ai/ai_usage_service.dart';
import '../../../core/services/ai/gemini_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/utils/requirements_check_list.dart';
import '../../../domain/entities/university_entity.dart';
import '../../UniversityDetails/cubit/university_details_cubit.dart';
import '../../UniversityDetails/cubit/university_details_state.dart';
import '../../ai/widgets/ai_document_generator.dart';
import '../../ai/widgets/ai_document_review_sheet.dart';

String? _toUrlOrNull(dynamic value) {
  if (value is String && value.startsWith('http')) return value;
  return null;
}

dynamic _rawDocValue(UniversityEntity? uni, String col) {
  if (uni == null) return null;
  switch (col) {
    case 'has_transcripts': return uni.hasTranscripts;
    case 'has_bachelor_cert': return uni.hasBachelorCert;
    case 'has_sop': return uni.hasSop;
    case 'has_cv': return uni.hasCv;
    case 'has_language_cert': return uni.hasLanguageCert;
    default: return null;
  }
}

class DocumentsScreen extends StatelessWidget {
  final UniversityEntity userFiles;

  const DocumentsScreen({super.key, required this.userFiles});

  @override
  Widget build(BuildContext context) {
    // 🎯 السحر هنا: تغليف الشاشة بالكيوبيت المسؤول عن الرفع لضمان عدم حدوث الخطأ الأحمر
    return BlocProvider(
      create: (context) => sl<UniversityDetailsCubit>()
        ..initializeUniversityData(
          percentage: 0,
          programs: [],
          university: userFiles,
        ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).translate('uploadDocuments'),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('uploadDocuments'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Files uploaded here will automatically be used for all your German university applications.",
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24.h),

              _AiDocReviewButton(),
              SizedBox(height: 16.h),

              // الآن سيجد هذا الويدجيت الـ Cubit فوقه مباشرة ولن يحدث Error
              RequirementsChecklistList(university: userFiles),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiDocReviewButton extends StatefulWidget {
  @override
  State<_AiDocReviewButton> createState() => _AiDocReviewButtonState();
}

class _AiDocReviewButtonState extends State<_AiDocReviewButton> {
  final _gemini = GeminiService();
  final _usageService = sl<AiUsageService>();
  int _remainingUses = 0;

  @override
  void initState() {
    super.initState();
    _loadRemaining();
  }

  Future<void> _loadRemaining() async {
    final remaining = await _usageService.getRemainingUses();
    if (mounted) setState(() => _remainingUses = remaining);
  }

  String get _langCode =>
      sl<LanguageProvider>().locale.languageCode;

  Future<void> _reviewDocuments(BuildContext context) async {
    final canUse = await _usageService.canUseAi();
    if (!canUse) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('monthlyLimitReached')),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // التحقق من وجود ملفات مرفوعة
    final uniForCheck = context.read<UniversityDetailsCubit>().state;
    final currentUni = uniForCheck is UniversitySaveStatus ? uniForCheck.currentUniversity : null;
    final hasAnyDoc = [
      _toUrlOrNull(currentUni?.hasTranscripts),
      _toUrlOrNull(currentUni?.hasBachelorCert),
      _toUrlOrNull(currentUni?.hasSop),
      _toUrlOrNull(currentUni?.hasCv),
      _toUrlOrNull(currentUni?.hasLanguageCert),
    ].any((url) => url is String);

    if (!hasAnyDoc) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).translate('noDocuments')}. ${AppLocalizations.of(context).translate('checkRequirements')}'),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final state = context.read<UniversityDetailsCubit>().state;
    if (state is! UniversitySaveStatus || state.studentProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('profileDataNotLoaded')),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final uni = state.currentUniversity;
    final uploadStatus = {
      'has_transcripts': _toUrlOrNull(state.currentUniversity?.hasTranscripts) != null,
      'has_bachelor_cert': _toUrlOrNull(state.currentUniversity?.hasBachelorCert) != null,
      'has_sop': _toUrlOrNull(state.currentUniversity?.hasSop) != null,
      'has_cv': _toUrlOrNull(state.currentUniversity?.hasCv) != null,
      'has_language_cert': _toUrlOrNull(state.currentUniversity?.hasLanguageCert) != null,
    };

    String stepLabel = '';
    void Function(void Function()) updateSheet = (_) {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          updateSheet = setSheetState;
          return _ReviewProgressSheet(stepLabel: stepLabel);
        },
      ),
    );

    try {
      final allReviews = <Map<String, dynamic>>[];
      final studentProfile = state.studentProfile!;
      final programName = 'German University Application';
      int validReviewCount = 0;

      final bool hasIelts = studentProfile['has_ielts'] == true;
      final bool hasToefl = studentProfile['has_toefl'] == true;
      final bool hasLanguageCertNeeded = hasIelts || hasToefl ||
          studentProfile['has_moi'] == true;

      final docConfigs = [
        ('has_transcripts', 'Academic Transcripts', 'transcripts'),
        ('has_bachelor_cert', 'Bachelor Certificate', 'bachelor_cert'),
        ('has_sop', 'SOP / Motivation Letter', 'sop'),
        ('has_cv', 'CV / Resume', 'cv'),
        if (hasLanguageCertNeeded)
          ('has_language_cert', 'Language Certificate', 'language_cert'),
      ];

      for (int i = 0; i < docConfigs.length; i++) {
        final (col, title, docType) = docConfigs[i];
        stepLabel = 'Downloading ${i + 1}/${docConfigs.length} — $title';
        updateSheet(() {});

        final String? url = _toUrlOrNull(_rawDocValue(uni, col));
        if (url != null) {
          try {
            stepLabel = 'Downloading ${i + 1}/${docConfigs.length} — $title';
            updateSheet(() {});

            final response = await Dio(BaseOptions(responseType: ResponseType.bytes)).get(url);
            if (response.statusCode != 200) {
              allReviews.add({
                'doc_type': docType,
                'title': title,
                'status': 'uploaded',
                'tips': ['File URL returned status ${response.statusCode}. Re-upload the document.'],
                'importance': 'medium',
                '_program_name': programName,
              });
              continue;
            }

            stepLabel = 'Analyzing ${i + 1}/${docConfigs.length} — $title';
            updateSheet(() {});

            final mimeType = response.headers.value('content-type') ?? 'application/pdf';
            final reviews = await _gemini.reviewDocumentWithPdf(
              programName: programName,
              docType: docType,
              title: title,
              pdfBytes: Uint8List.fromList(response.data as List<int>),
              mimeType: mimeType,
              languageCode: _langCode,
            );
            if (GeminiService.hasValidFeedback(reviews)) {
              validReviewCount++;
            }
            allReviews.add({
              'doc_type': docType,
              'title': title,
              'status': 'uploaded',
              'tips': reviews.map((r) => r['suggestion']?.toString() ?? '').toList(),
              'importance': reviews.isNotEmpty
                  ? reviews.map((r) => r['severity']?.toString() ?? 'medium')
                      .fold<String>('medium',
                          (a, b) => b == 'high' ? 'high' : a)
                  : 'medium',
              '_program_name': programName,
            });
          } on DioException catch (e) {
            final msg = e.type == DioExceptionType.connectionTimeout
                ? 'Download timed out. Check your internet connection.'
                : e.type == DioExceptionType.badResponse
                    ? 'Server returned ${e.response?.statusCode}. Re-upload the document.'
                    : 'Could not download the file. Check your connection.';
            allReviews.add({
              'doc_type': docType,
              'title': title,
              'status': 'uploaded',
              'tips': [msg],
              'importance': 'medium',
              '_program_name': programName,
            });
          } catch (e) {
            allReviews.add({
              'doc_type': docType,
              'title': title,
              'status': 'uploaded',
              'tips': ['AI analysis failed: ${e.toString()}'],
              'importance': 'medium',
              '_program_name': programName,
            });
          }
        } else {
          if (col == 'has_language_cert') continue; // optional
          stepLabel = 'Analyzing ${i + 1}/${docConfigs.length} — $title';
          updateSheet(() {});

          final suggestions = await _gemini.getDocumentSuggestions(
            studentProfile: studentProfile,
            programDetails: {
              'name': programName,
              'major': studentProfile['target_major'] ?? '',
              'degree': studentProfile['degree_level'] ?? '',
              'required_gpa': 0,
              'requires_ielts': false,
              'min_ielts': 0,
              'accepts_moi': false,
              'language': studentProfile['language_preference'] ?? '',
            },
            uploadStatus: uploadStatus,
            languageCode: _langCode,
          );
          final docTip = suggestions.where((t) => t['doc_type']?.toString() == docType).toList();
          allReviews.add({
            'doc_type': docType,
            'title': title,
            'status': 'missing',
            'tips': docTip.isNotEmpty
                ? (docTip.first['tips'] as List?)?.cast<String>() ?? []
                : ['Upload this document to get AI feedback.'],
            'importance': docTip.isNotEmpty
                ? (docTip.first['importance']?.toString() ?? 'medium')
                : 'medium',
            '_program_name': programName,
          });
        }
      }

      if (validReviewCount > 0) {
        await _usageService.recordUsage();
      }
      await _loadRemaining();

      if (mounted) {
        Navigator.pop(context);
        _showReviewSheet(context, allReviews);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showReviewSheet(context, [], error: e.toString());
      }
    }
  }

  void _showReviewSheet(BuildContext context, List<Map<String, dynamic>> reviews, {String? error}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiDocumentReviewSheet(
        reviews: reviews,
        error: error,
        onRetry: error != null ? () {
          Navigator.pop(context);
          _reviewDocuments(context);
        } : null,
        onGenerateDocument: (ctx, docType, programName) {
          final state = ctx.read<UniversityDetailsCubit>().state;
          final studentProfile = state is UniversitySaveStatus ? state.studentProfile : null;
          Navigator.pop(ctx);
          _openGenerator(ctx, docType, programName, studentProfile);
        },
      ),
    );
  }

  void _openGenerator(BuildContext ctx, String docType, String programName, Map<String, dynamic>? studentProfile) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenerateSheet(
        programName: programName.isNotEmpty ? programName : 'German University Application',
        universityName: '',
        degreeType: 'Master',
        major: studentProfile?['target_major']?.toString() ?? '',
        studentName: studentProfile?['username']?.toString() ?? '',
        studentBackground: 'GPA: ${studentProfile?['gpa'] ?? 'N/A'}, Major: ${studentProfile?['target_major'] ?? 'N/A'}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingLabel = AppLocalizations.of(context).translate('remainingUses');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _reviewDocuments(context),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(
              AppLocalizations.of(context).translate('aiReview'),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (_remainingUses > 0)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              '$remainingLabel $_remainingUses/10',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// _ReviewProgressSheet — loading indicator with step label
// ─────────────────────────────────────────────────────────
class _ReviewProgressSheet extends StatelessWidget {
  final String stepLabel;
  const _ReviewProgressSheet({required this.stepLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 16.h),
          Text(
            'Reviewing Your Documents',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            stepLabel.isNotEmpty ? stepLabel : 'Starting...',
            style: TextStyle(
              fontSize: 13.sp,
              color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
