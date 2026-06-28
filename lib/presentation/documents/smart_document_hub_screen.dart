import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/ai/ai_usage_service.dart';
import '../../core/services/ai/gemini_service.dart';
import '../../core/services/ai/review_cache_service.dart';
import '../../core/services/review_service.dart';
import '../../core/services/services_locator.dart';
import '../../core/themes/app_colors.dart';
import '../../core/utils/missing_doc_templates.dart';
import '../../domain/entities/university_entity.dart';
import '../../domain/repositories/applications_repository.dart';
import '../MyApplications/cubit/my_applications_cubits.dart';
import '../MyApplications/cubit/my_applications_states.dart';
import '../ai/widgets/ai_document_generator.dart';
import '../ai/widgets/ai_document_review_sheet.dart';

class _DocInfo {
  final String column;
  final String title;
  final String localeKey;
  final String docType;
  final IconData icon;

  const _DocInfo({
    required this.column,
    required this.title,
    required this.localeKey,
    required this.docType,
    required this.icon,
  });
}

const _docInfos = [
  _DocInfo(column: 'has_transcripts', title: 'Academic Transcripts', localeKey: 'academicTranscripts', docType: 'transcripts', icon: Icons.menu_book_rounded),
  _DocInfo(column: 'has_bachelor_cert', title: 'Bachelor Certificate', localeKey: 'bachelorCertificate', docType: 'bachelor_cert', icon: Icons.workspace_premium_rounded),
  _DocInfo(column: 'has_sop', title: 'Motivation Letter / SOP', localeKey: 'sopMotivationLetter', docType: 'sop', icon: Icons.article_rounded),
  _DocInfo(column: 'has_cv', title: 'CV / Resume', localeKey: 'cvResume', docType: 'cv', icon: Icons.description_rounded),
  _DocInfo(column: 'has_language_cert', title: 'Language Certificate', localeKey: 'languageCertOptional', docType: 'language_cert', icon: Icons.language_rounded),
  _DocInfo(column: 'has_german_cert_doc', title: 'German Language Certificate', localeKey: 'germanCert', docType: 'german_cert', icon: Icons.translate_rounded),
];

class SmartDocumentHubScreen extends StatefulWidget {
  const SmartDocumentHubScreen({super.key});

  @override
  State<SmartDocumentHubScreen> createState() => _SmartDocumentHubScreenState();
}

class _SmartDocumentHubScreenState extends State<SmartDocumentHubScreen> {
  final _gemini = sl<GeminiService>();
  final _usage = sl<AiUsageService>();
  final _repo = sl<ApplicationsRepository>();
  final _cache = sl<ReviewCacheService>();

  List<UniversityEntity> _universities = [];
  Map<String, dynamic>? _profile;
  Map<String, double> _uploadProgress = {};
  bool _isLoading = true;
  bool _reviewing = false;

  String? _url(String col) {
    if (_profile == null) return null;
    final v = _profile![col];
    if (v is String && v.startsWith('http')) return v;
    return null;
  }

  bool _hasDoc(String col) => _url(col) != null;

  int get _uploadedCount => _docInfos.where((d) => _hasDoc(d.column)).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      List<UniversityEntity> list = [];
      try {
        final appsState = context.read<MyApplicationsCubit>().state;
        if (appsState is MyApplicationsLoaded) {
          list = appsState.allApplications;
        }
      } catch (_) {
        // Cubit not available — proceed without application list
      }
      final userId = Supabase.instance.client.auth.currentUser?.id;
      Map<String, dynamic>? profile;
      if (userId != null) {
        profile = await Supabase.instance.client
            .from('profiles')
            .select('id, username, gpa, target_major, degree_level, has_ielts, ielts_score, has_toefl, toefl_score, nationality, has_transcripts, has_bachelor_cert, has_sop, has_cv, has_language_cert, has_german_cert_doc')
            .eq('id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
      }
      if (mounted) setState(() {
        _universities = list;
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _programsNeedingDoc(String col) {
    final result = <String>[];
    for (final u in _universities) {
      for (final p in u.programs) {
        if (col == 'has_language_cert' && !p.requiresIelts) continue;
        result.add('${u.name} — ${p.programName}');
      }
    }
    return result;
  }

  Future<void> _pickAndUpload(String col) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.single.path;
    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access file path'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    final file = File(filePath);
    setState(() => _uploadProgress[col] = 0);

    try {
      final url = await _repo.uploadDocument(
        universityId: 'global',
        columnName: col,
        file: file,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress[col] = p);
        },
      );
      if (mounted) {
        setState(() {
          if (_profile != null) _profile![col] = url;
          _uploadProgress.remove(col);
        });
        _autoReview(col, url);
      }
    } catch (e) {
      if (mounted) setState(() => _uploadProgress.remove(col));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>?> _showProgress({
    required String title,
    required Future<List<Map<String, dynamic>>?> Function(void Function(String) updateStatus) task,
  }) async {
    if (!mounted) return null;
    final t = AppLocalizations.of(context);
    final statusNotifier = ValueNotifier<String>(t.translate('starting'));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewProgressSheet(title: title, status: statusNotifier),
    );
    List<Map<String, dynamic>>? result;
    try {
      result = await task((msg) => statusNotifier.value = msg);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
    return result;
  }

  /// Normalizes Gemini's raw response ([issue]/[severity]/[suggestion]) into
  /// the sheet's expected format ([status]/[title]/[doc_type]/[tips]/[importance]).
  List<Map<String, dynamic>> _normalizeReviews(
    List<Map<String, dynamic>> geminiReviews,
    _DocInfo doc,
  ) {
    if (geminiReviews.isEmpty) return [];

    final tips = geminiReviews.map((r) {
      final issue = r['issue']?.toString() ?? '';
      final suggestion = r['suggestion']?.toString() ?? '';
      if (issue.isNotEmpty && suggestion.isNotEmpty) return '$issue — $suggestion';
      return issue.isNotEmpty ? issue : suggestion;
    }).toList();

    final severities = geminiReviews
        .map((r) => r['severity']?.toString() ?? '')
        .toList();
    String importance = 'medium';
    if (severities.any((s) => s == 'high')) {
      importance = 'high';
    } else if (severities.any((s) => s == 'low')) {
      importance = 'low';
    }

    return [
      {
        'doc_type': doc.docType,
        'status': 'uploaded',
        'title': doc.localeKey,
        'importance': importance,
        'tips': tips,
      },
    ];
  }

  Future<void> _autoReview(String col, String url) async {
    if (!await _usage.canUseReview()) {
      if (mounted) context.push('/premium');
      return;
    }
    final docInfo = _docInfos.firstWhere((d) => d.column == col);
    final cached = await _cache.getCachedReview(docType: col, currentUrl: url);
    if (cached != null) {
      final normalized = _normalizeReviews(cached, docInfo);
      if (normalized.isNotEmpty && mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AiDocumentReviewSheet(reviews: normalized),
        );
      }
      return;
    }

    final progName = _universities.isNotEmpty && _universities.first.programs.isNotEmpty
        ? _universities.first.programs.first.programName
        : 'Master\'s Program';

    final reviews = await _showProgress(
      title: '${AppLocalizations.of(context).translate('reviewing')} ${AppLocalizations.of(context).translate(docInfo.localeKey)}',
      task: (updateStatus) async {
        updateStatus(AppLocalizations.of(context).translate('downloadingDocument'));
        final dio = Dio();
        final response = await dio.get<Uint8List>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data;
        if (bytes == null) return null;

        updateStatus(AppLocalizations.of(context).translate('analyzingWithAi'));
        final r = await _gemini.reviewDocumentWithPdf(
          studentProfile: _profile ?? {},
          programName: progName,
          docType: docInfo.docType,
            title: AppLocalizations.of(context).translate(docInfo.localeKey),
          pdfBytes: bytes,
        );

        if (GeminiService.hasValidFeedback(r)) {
          updateStatus(AppLocalizations.of(context).translate('savingFeedback'));
          await _usage.recordUsage();
          await _cache.storeReview(docType: col, url: url, reviews: r);
          await ReviewService.registerPositiveAction();
        }

        updateStatus(AppLocalizations.of(context).translate('done'));
        return r;
      },
    );

    if (reviews != null && reviews.isNotEmpty && mounted) {
      final normalized = _normalizeReviews(reviews, docInfo);
      if (normalized.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AiDocumentReviewSheet(reviews: normalized),
        );
      }
    }
  }

  Future<void> _reviewAll() async {
    if (_reviewing) return;
    setState(() => _reviewing = true);

    final results = await _showProgress(
        title: AppLocalizations.of(context).translate('aiReviewAllDocuments'),
      task: (updateStatus) async {
        final progName = _universities.isNotEmpty && _universities.first.programs.isNotEmpty
            ? _universities.first.programs.first.programName
            : AppLocalizations.of(context).translate('mastersProgram');
        final allResults = <Map<String, dynamic>>[];

        for (final doc in _docInfos) {
          final url = _url(doc.column);
          if (url != null) {
            updateStatus('${AppLocalizations.of(context).translate('downloading')} ${AppLocalizations.of(context).translate(doc.localeKey)}...');
            final cached = await _cache.getCachedReview(docType: doc.column, currentUrl: url);
            if (cached != null) {
              allResults.addAll(_normalizeReviews(cached, doc));
              continue;
            }
            try {
              updateStatus('${AppLocalizations.of(context).translate('downloading')} ${AppLocalizations.of(context).translate(doc.localeKey)}...');
              final dio = Dio();
              final response = await dio.get<Uint8List>(
                url,
                options: Options(responseType: ResponseType.bytes),
              );
              final bytes = response.data;
              if (bytes == null) continue;

              updateStatus('${AppLocalizations.of(context).translate('analyzingWithAi')} ${AppLocalizations.of(context).translate(doc.localeKey)}...');
              final reviews = await _gemini.reviewDocumentWithPdf(
                studentProfile: _profile ?? {},
                programName: progName,
                docType: doc.docType,
                title: AppLocalizations.of(context).translate(doc.localeKey),
                pdfBytes: bytes,
              );
              if (GeminiService.hasValidFeedback(reviews)) {
                allResults.addAll(_normalizeReviews(reviews, doc));
                await _cache.storeReview(docType: doc.column, url: url, reviews: reviews);
              }
            } catch (_) {}
          } else {
            allResults.add(MissingDocTemplates.suggestionForDocType(doc.docType, _profile ?? {}));
          }
        }

        if (allResults.isNotEmpty) {
          updateStatus(AppLocalizations.of(context).translate('finalizing'));
          await _usage.recordUsage();
          await ReviewService.registerPositiveAction();
        }

        updateStatus(AppLocalizations.of(context).translate('done'));
        return allResults;
      },
    );

    if (mounted) {
      setState(() => _reviewing = false);
      if (results != null && results.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AiDocumentReviewSheet(reviews: results),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('smartDocumentHub')),
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _reviewing ? null : _reviewAll,
              icon: _reviewing
                  ? SizedBox(width: 16.r, height: 16.r, child: CircularProgressIndicator(strokeWidth: 2.r))
                  : Icon(Icons.auto_awesome, size: 18.sp),
              label: Text(_reviewing ? AppLocalizations.of(context).translate('reviewing') : AppLocalizations.of(context).translate('aiReviewAll')),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    return Container(
      color: bg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        children: [
          _buildProgressCard(isDark),
          SizedBox(height: 20.h),
          if (_universities.isEmpty) _buildEmptyState(isDark),
          ..._docInfos.map((doc) => _buildDocSection(doc, isDark)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(bool isDark) {
    final total = _docInfos.length;
    final done = _uploadedCount;
    final fraction = total > 0 ? done / total : 0.0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 24.sp),
              SizedBox(width: 10.w),
              Text(AppLocalizations.of(context).translate('documentReadiness'),
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$done',
                  style: TextStyle(color: Colors.white, fontSize: 40.sp, fontWeight: FontWeight.bold)),
              Text('/$total',
                  style: TextStyle(color: Colors.white60, fontSize: 20.sp)),
              SizedBox(width: 12.w),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _universities.isNotEmpty
                ? AppLocalizations.of(context).translate('acrossSavedUniversities').replaceAll('{count}', _universities.length.toString()).replaceAll('{plural}', _universities.length == 1 ? 'y' : 'ies')
                : AppLocalizations.of(context).translate('noSavedUniversities'),
            style: TextStyle(color: Colors.white60, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.r),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.bookmark_border, size: 48.sp, color: const Color(0xFF94A3B8)),
          SizedBox(height: 12.h),
          Text(AppLocalizations.of(context).translate('saveUniversitiesFirst'),
              style: TextStyle(fontSize: 15.sp, color: isDark ? AppColors.textMuted : const Color(0xFF64748B))),
          SizedBox(height: 4.h),
          Text(AppLocalizations.of(context).translate('documentsShowRequirements'),
              style: TextStyle(fontSize: 13.sp, color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildDocSection(_DocInfo doc, bool isDark) {
    final uploaded = _hasDoc(doc.column);
    final url = _url(doc.column);
    final isUploading = _uploadProgress.containsKey(doc.column);
    final progress = _uploadProgress[doc.column] ?? 0.0;
    final programs = _programsNeedingDoc(doc.column);

    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: uploaded
                        ? const Color(0xFFDCFCE7)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(doc.icon,
                      size: 22.r,
                      color: uploaded ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).translate(doc.localeKey),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp,
                              color: isDark ? AppColors.textMain : const Color(0xFF0F172A))),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: uploaded ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              uploaded ? AppLocalizations.of(context).translate('uploaded') : AppLocalizations.of(context).translate('missing'),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: uploaded ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                          if (programs.length > 1) ...[
                            SizedBox(width: 8.w),
                            Text(AppLocalizations.of(context).translate('neededByPrograms').replaceAll('{count}', programs.length.toString()),
                                style: TextStyle(fontSize: 11.sp,
                                    color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isUploading)
                  uploaded
                      ? Icon(Icons.check_circle_rounded, color: const Color(0xFF16A34A), size: 24.r)
                      : Icon(Icons.radio_button_unchecked, color: const Color(0xFFCBD5E1), size: 24.r),
              ],
            ),
          ),

          if (isUploading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: border,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(AppLocalizations.of(context).translate('uploadingPercent').replaceAll('{percent}', (progress * 100).toInt().toString()),
                      style: TextStyle(fontSize: 11.sp, color: const Color(0xFF4F46E5))),
                  SizedBox(height: 12.h),
                ],
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.r),
            child: Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _actionChip(
                  icon: uploaded ? Icons.swap_horiz_rounded : Icons.upload_file_rounded,
                  label: uploaded ? AppLocalizations.of(context).translate('replace') : AppLocalizations.of(context).translate('upload'),
                  onTap: () => _pickAndUpload(doc.column),
                  color: const Color(0xFF4F46E5),
                ),
                if (uploaded && url != null)
                  _actionChip(
                    icon: Icons.auto_awesome,
                    label: AppLocalizations.of(context).translate('aiReviewShort'),
                    onTap: () => _autoReview(doc.column, url),
                    color: const Color(0xFF7C3AED),
                  ),
                if (doc.docType == 'sop' || doc.docType == 'cv')
                  _actionChip(
                    icon: Icons.auto_fix_high_rounded,
                    label: AppLocalizations.of(context).translate('generate'),
                    onTap: () => _openGenerator(doc.docType),
                    color: const Color(0xFF0891B2),
                  ),
              ],
            ),
          ),

          if (programs.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: programs.take(4).map((p) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(p,
                        style: TextStyle(fontSize: 10.sp,
                            color: isDark ? AppColors.textMuted : const Color(0xFF64748B))),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionChip({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.r, color: color),
              SizedBox(width: 4.w),
              Text(label,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  String _buildBackground() {
    if (_profile == null) return AppLocalizations.of(context).translate('notProvided');
    final parts = <String>[];
    if (_profile!['gpa'] != null) parts.add('GPA: ${_profile!['gpa']}');
    if (_profile!['target_major'] != null) parts.add('Major: ${_profile!['target_major']}');
    if (_profile!['degree_level'] != null) parts.add('Degree: ${_profile!['degree_level']}');
    if (_profile!['has_ielts'] == true && _profile!['ielts_score'] != null) {
      parts.add('IELTS: ${_profile!['ielts_score']}');
    }
    if (_profile!['has_toefl'] == true && _profile!['toefl_score'] != null) {
      parts.add('TOEFL: ${_profile!['toefl_score']}');
    }
    if (_profile!['nationality'] != null) parts.add('Country: ${_profile!['nationality']}');
    return parts.isNotEmpty ? parts.join(', ') : AppLocalizations.of(context).translate('notProvided');
  }

  void _openGenerator(String docType) {
    final progName = _universities.isNotEmpty && _universities.first.programs.isNotEmpty
        ? _universities.first.programs.first.programName
        : AppLocalizations.of(context).translate('mastersProgram');
    final uniName = _universities.isNotEmpty ? _universities.first.name : AppLocalizations.of(context).translate('university');

    final univ = _universities.isNotEmpty ? _universities.first : null;
    final prog = univ != null && univ.programs.isNotEmpty ? univ.programs.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenerateSheet(
        programName: progName,
        universityName: uniName,
        degreeType: prog?.degreeType ?? "Master's",
        major: prog?.major ?? '',
        studentName: _profile?['username'] as String? ?? AppLocalizations.of(context).translate('username'),
        studentBackground: _buildBackground(),
        transcriptsUrl: _url('has_transcripts'),
        bachelorCertUrl: _url('has_bachelor_cert'),
        cvUrl: _url('has_cv'),
      ),
    );
  }
}

class _ReviewProgressSheet extends StatefulWidget {
  final String title;
  final ValueNotifier<String> status;
  const _ReviewProgressSheet({required this.title, required this.status});

  @override
  State<_ReviewProgressSheet> createState() => _ReviewProgressSheetState();
}

class _ReviewProgressSheetState extends State<_ReviewProgressSheet> {
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status.value;
    widget.status.addListener(_onStatusChange);
  }

  @override
  void dispose() {
    widget.status.removeListener(_onStatusChange);
    super.dispose();
  }

  void _onStatusChange() {
    if (mounted) setState(() => _currentStatus = widget.status.value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final steps = [loc.translate('downloading'), loc.translate('analyzingWithAi'), loc.translate('savingFeedback'), loc.translate('done')];
    final currentStep = steps.indexWhere((s) => _currentStatus.contains(s.replaceFirst('...', '')));
    final activeStep = currentStep >= 0 ? currentStep : (_currentStatus == loc.translate('done') ? steps.length - 1 : 0);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40.w, height: 4, decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          )),
          SizedBox(height: 24.h),
          Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 24.h),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isActive = i == activeStep;
            final isDone = i < activeStep || (i == steps.length - 1 && _currentStatus == loc.translate('done'));
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 24.r,
                    height: 24.r,
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFF16A34A) : isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: isDone
                        ? Icon(Icons.check, size: 14.sp, color: Colors.white)
                        : isActive
                            ? SizedBox(width: 12.r, height: 12.r, child: CircularProgressIndicator(
                                strokeWidth: 2.r, color: Colors.white))
                            : null,
                  ),
                  SizedBox(width: 12.w),
                  Text(step, style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isDone || isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  )),
                ],
              ),
            );
          }),
          SizedBox(height: 8.h),
          Text(_currentStatus,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}
