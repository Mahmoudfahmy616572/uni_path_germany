import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/ai/ai_usage_service.dart';
import '../../../core/services/ai/gemini_service.dart';
import '../../../core/services/ai/review_cache_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/missing_doc_templates.dart';
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
    case 'has_transcripts':
      return uni.hasTranscripts;
    case 'has_bachelor_cert':
      return uni.hasBachelorCert;
    case 'has_sop':
      return uni.hasSop;
    case 'has_cv':
      return uni.hasCv;
    case 'has_language_cert':
      return uni.hasLanguageCert;
    default:
      return null;
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
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).translate('uploadDescription'),
                style: const TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24.h),

              _AiDocReviewButton(),
              SizedBox(height: 12.h),
              _AiGenerateButton(),
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
  final _gemini = sl<GeminiService>();
  final _usageService = sl<AiUsageService>();
  final _cacheService = sl<ReviewCacheService>();
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

  String get _langCode => sl<LanguageProvider>().locale.languageCode;

  Future<void> _reviewDocuments(BuildContext context) async {
    final local = AppLocalizations.of(context);
    final canUse = await _usageService.canUseAi();
    if (!canUse) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('monthlyLimitReached')),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // التحقق من وجود ملفات مرفوعة
    final uniForCheck = context.read<UniversityDetailsCubit>().state;
    final currentUni = uniForCheck is UniversitySaveStatus
        ? uniForCheck.currentUniversity
        : null;
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
            content: Text(
                AppLocalizations.of(context).translate('profileDataNotLoaded')),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final uni = state.currentUniversity;
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
      final bool hasLanguageCertNeeded =
          hasIelts || hasToefl || studentProfile['has_moi'] == true;

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
        stepLabel =
            '${local.translate('downloadLabel')} ${i + 1}/${docConfigs.length} — $title';
        updateSheet(() {});

        final String? url = _toUrlOrNull(_rawDocValue(uni, col));
        if (url != null) {
          // Check cache first — if file URL hasn't changed, reuse old review
          final cached = await _cacheService.getCachedReview(
            docType: docType,
            currentUrl: url,
          );
          if (cached != null) {
            allReviews.add({
              'doc_type': docType,
              'title': title,
              'status': 'uploaded',
              'tips':
                  cached.map((r) => r['suggestion']?.toString() ?? '').toList(),
              'importance': cached.isNotEmpty
                  ? cached
                      .map((r) => r['severity']?.toString() ?? 'medium')
                      .fold<String>(
                          'medium', (a, b) => b == 'high' ? 'high' : a)
                  : 'medium',
              '_program_name': programName,
            });
            stepLabel =
                '${local.translate('cachedLabel')} ${i + 1}/${docConfigs.length} — $title';
            updateSheet(() {});
            await Future.delayed(const Duration(milliseconds: 300));
            continue;
          }

          try {
            stepLabel =
                '${local.translate('downloadLabel')} ${i + 1}/${docConfigs.length} — $title';
            updateSheet(() {});

            // Retry up to 3 times for transient server errors (429, 502, 503)
            Response? response;
            const maxDownloadRetries = 3;
            for (int attempt = 0; attempt < maxDownloadRetries; attempt++) {
              try {
                response = await Dio(
                  BaseOptions(responseType: ResponseType.bytes),
                ).get(url);
                break;
              } on DioException catch (e) {
                final isTransient = e.type == DioExceptionType.badResponse &&
                    (e.response?.statusCode == 429 ||
                        e.response?.statusCode == 502 ||
                        e.response?.statusCode == 503);
                if (attempt < maxDownloadRetries - 1 && isTransient) {
                  await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
                  continue;
                }
                rethrow;
              }
            }

            if (response == null || response.statusCode != 200) {
              allReviews.add({
                'doc_type': docType,
                'title': title,
                'status': 'uploaded',
                'tips': [
                  response != null
                      ? local
                          .translate('serverReturned')
                          .replaceAll('{code}', response.statusCode.toString())
                      : local.translate('couldNotDownload'),
                ],
                'importance': 'medium',
                '_program_name': programName,
              });
              continue;
            }

            stepLabel =
                '${local.translate('analyzeLabel')} ${i + 1}/${docConfigs.length} — $title';
            updateSheet(() {});

            // Delay between docs to avoid hitting Gemini rate limit (429)
            if (i > 0) await Future.delayed(const Duration(seconds: 2));

            final mimeType =
                response.headers.value('content-type') ?? 'application/pdf';
            final reviews = await _gemini.reviewDocumentWithPdf(
              studentProfile: studentProfile,
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
            await _cacheService.storeReview(
              docType: docType,
              url: url,
              reviews: reviews,
            );
            allReviews.add({
              'doc_type': docType,
              'title': title,
              'status': 'uploaded',
              'tips': reviews
                  .map((r) => r['suggestion']?.toString() ?? '')
                  .toList(),
              'importance': reviews.isNotEmpty
                  ? reviews
                      .map((r) => r['severity']?.toString() ?? 'medium')
                      .fold<String>(
                          'medium', (a, b) => b == 'high' ? 'high' : a)
                  : 'medium',
              '_program_name': programName,
            });
          } on DioException catch (e) {
            final msg = e.type == DioExceptionType.connectionTimeout
                ? local.translate('downloadTimedOut')
                : e.type == DioExceptionType.badResponse
                    ? local.translate('serverReturned').replaceAll(
                        '{code}', e.response?.statusCode.toString() ?? '')
                    : local.translate('couldNotDownload');
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
              'tips': [
                local.translate('aiFailed').replaceAll('{error}', e.toString())
              ],
              'importance': 'medium',
              '_program_name': programName,
            });
          }
        } else {
          stepLabel =
              '${local.translate('recommendationsLabel')} ${i + 1}/${docConfigs.length} — $title';
          updateSheet(() {});

          final staticSuggestions =
              MissingDocTemplates.getSuggestions(studentProfile);
          final docTip = staticSuggestions
              .where((t) => t['doc_type']?.toString() == docType)
              .toList();
          allReviews.add({
            'doc_type': docType,
            'title': title,
            'status': 'missing',
            'tips': docTip.isNotEmpty
                ? (docTip.first['tips'] as List?)?.cast<String>() ?? []
                : [local.translate('uploadThisDoc')],
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

  void _showReviewSheet(
      BuildContext context, List<Map<String, dynamic>> reviews,
      {String? error}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiDocumentReviewSheet(
        reviews: reviews,
        error: error,
        onRetry: error != null
            ? () {
                Navigator.pop(context);
                _reviewDocuments(context);
              }
            : null,
        onGenerateDocument: (ctx, docType, programName) {
          final state = ctx.read<UniversityDetailsCubit>().state;
          final studentProfile =
              state is UniversitySaveStatus ? state.studentProfile : null;
          Navigator.pop(ctx);
          _openGenerator(ctx, docType, programName, studentProfile);
        },
      ),
    );
  }

  void _openGenerator(BuildContext ctx, String docType, String programName,
      Map<String, dynamic>? studentProfile) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenerateSheet(
        programName: programName.isNotEmpty
            ? programName
            : 'German University Application',
        universityName: '',
        degreeType: 'Master',
        major: studentProfile?['target_major']?.toString() ?? '',
        studentName: studentProfile?['username']?.toString() ?? '',
        studentBackground:
            'GPA: ${studentProfile?['gpa'] ?? 'N/A'}, Major: ${studentProfile?['target_major'] ?? 'N/A'}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingLabel =
        AppLocalizations.of(context).translate('remainingUses');
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
// _AiGenerateButton — CV/SOP generation
// ─────────────────────────────────────────────────────────
class _AiGenerateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final state = context.read<UniversityDetailsCubit>().state;
          final profile =
              state is UniversitySaveStatus ? state.studentProfile : null;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => GenerateSheet(
              programName: 'German University Application',
              universityName: '',
              degreeType: 'Master',
              major: profile?['target_major']?.toString() ?? '',
              studentName: profile?['username']?.toString() ?? '',
              studentBackground:
                  'GPA: ${profile?['gpa'] ?? 'N/A'}, Major: ${profile?['target_major'] ?? 'N/A'}',
            ),
          );
        },
        icon: const Icon(Icons.auto_awesome, size: 16),
        label: Text(
          'Generate CV / SOP with AI',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8B5CF6),
          side: const BorderSide(color: Color(0xFF8B5CF6)),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _ReviewProgressSheet — animated AI loading indicator
// ─────────────────────────────────────────────────────────
class _ReviewProgressSheet extends StatefulWidget {
  final String stepLabel;
  const _ReviewProgressSheet({required this.stepLabel});

  @override
  State<_ReviewProgressSheet> createState() => _ReviewProgressSheetState();
}

class _ReviewProgressSheetState extends State<_ReviewProgressSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, opacity, child) => Opacity(
        opacity: opacity,
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF6366F1),
                            Color(0xFF4F46E5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const _AiSparkleLoader(),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppLocalizations.of(context).translate('reviewingDocuments'),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.stepLabel.isNotEmpty
                  ? widget.stepLabel
                  : AppLocalizations.of(context).translate('starting'),
              style: TextStyle(
                fontSize: 13.sp,
                color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: 180.w,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3.r),
                child: LinearProgressIndicator(
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFF8B5CF6),
                  minHeight: 3.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSparkleLoader extends StatefulWidget {
  const _AiSparkleLoader();

  @override
  State<_AiSparkleLoader> createState() => _AiSparkleLoaderState();
}

class _AiSparkleLoaderState extends State<_AiSparkleLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _spin;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _spin = Tween<double>(begin: 0, end: 360).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: CustomPaint(
        size: const Size(44, 44),
        painter: _AiSparklePainter(),
      ),
    );
  }
}

class _AiSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = (i * 90) * (3.14159 / 180);
      final dist = size.width * 0.35;
      final x = center.dx + dist * math.cos(angle);
      final y = center.dy + dist * math.sin(angle);

      final path = Path()
        ..moveTo(x, y - 5)
        ..lineTo(x + 3, y)
        ..lineTo(x, y + 5)
        ..lineTo(x - 3, y)
        ..close();
      canvas.drawPath(path, paint);
    }

    canvas.drawCircle(center, 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
