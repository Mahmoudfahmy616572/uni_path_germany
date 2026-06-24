import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/ai/ai_usage_service.dart';
import '../../../core/services/ai/gemini_service.dart';
import '../../../core/services/services_locator.dart';

// ─────────────────────────────────────────────────────────
// AiDocumentGenerator — card that opens the generate sheet
// ─────────────────────────────────────────────────────────
class AiDocumentGenerator extends StatelessWidget {
  final String programName;
  final String universityName;
  final String degreeType;
  final String major;
  final String studentName;
  final String studentBackground;

  const AiDocumentGenerator({
    super.key,
    required this.programName,
    required this.universityName,
    required this.degreeType,
    required this.major,
    required this.studentName,
    required this.studentBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 18.sp,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Document Generator',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'CV & Motivation Letter',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Generate a tailored CV (Lebenslauf) or Motivation Letter optimized for $programName.',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openGenerator(context),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                'Generate Now',
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
        ],
      ),
    );
  }

  void _openGenerator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => GenerateSheet(
        programName: programName,
        universityName: universityName,
        degreeType: degreeType,
        major: major,
        studentName: studentName,
        studentBackground: studentBackground,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// GenerateSheet — full generation flow in a bottom sheet
// ─────────────────────────────────────────────────────────
class GenerateSheet extends StatefulWidget {
  final String programName;
  final String universityName;
  final String degreeType;
  final String major;
  final String studentName;
  final String studentBackground;
  final String? transcriptsUrl;
  final String? bachelorCertUrl;
  final String? cvUrl;
  final void Function(File pdfFile, String docType)? onReplaceFile;

  const GenerateSheet({
    super.key,
    required this.programName,
    required this.universityName,
    required this.degreeType,
    required this.major,
    required this.studentName,
    required this.studentBackground,
    this.transcriptsUrl,
    this.bachelorCertUrl,
    this.cvUrl,
    this.onReplaceFile,
  });

  @override
  State<GenerateSheet> createState() => GenerateSheetState();
}

class GenerateSheetState extends State<GenerateSheet> {
  final _gemini = sl<GeminiService>();
  final _usageService = sl<AiUsageService>();

  String get _langCode =>
      sl<LanguageProvider>().locale.languageCode;

  // Form state
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bgCtrl;
  String _docType = 'cv';
  bool _generating = false;
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.studentName);
    _bgCtrl = TextEditingController(text: widget.studentBackground);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  /// Strip markdown formatting but PRESERVE hyperlinks [text](url).
  String _stripMarkdown(String text) {
    // Protect markdown links [text](url) with placeholders
    final links = <String, String>{};
    var protected = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) {
        final key = '§LK${links.length}§';
        links[key] = m[0]!;
        return key;
      },
    );

    final buf = StringBuffer();
    for (final line in protected.split('\n')) {
      var l = line;
      if (RegExp(r'^[\s]*[-*_]{3,}[\s]*$').hasMatch(l)) { buf.writeln(); continue; }
      l = l.replaceAllMapped(RegExp(r'^#{1,6}\s+'), (_) => '');
      l = l.replaceAll('**', '').replaceAll('*', '');
      l = l.replaceAll('__', '').replaceAll('_', '');
      l = l.replaceAllMapped(RegExp(r'^>\s?'), (_) => '');
      l = l.replaceAllMapped(RegExp(r'^[\s]*[-*+]\s+'), (_) => '  ');
      l = l.replaceAllMapped(RegExp(r'^\s*\d+[.)]\s+'), (_) => '  ');
      l = l.replaceAll('[ ]', '').replaceAll('[x]', '').replaceAll('[X]', '');
      l = l.replaceAll('`', '').replaceAll('|', '');
      l = l.trim();
      buf.writeln(l);
    }

    var result = buf.toString();
    links.forEach((k, v) { result = result.replaceAll(k, v); });
    return result.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  /// Parse hyperlinks [text](url) from a line into segments.
  /// Returns pairs of (isLink, text/url).
  List<List<dynamic>> _parseLine(String line) {
    final segments = <List<dynamic>>[];
    final regex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    int lastEnd = 0;
    for (final m in regex.allMatches(line)) {
      if (m.start > lastEnd) {
        segments.add([false, line.substring(lastEnd, m.start)]);
      }
      segments.add([true, m.group(1)!, m.group(2)!]);
      lastEnd = m.end;
    }
    if (lastEnd < line.length) {
      segments.add([false, line.substring(lastEnd)]);
    }
    if (segments.isEmpty) segments.add([false, line]);
    return segments;
  }

  Future<File> _generatePdf() async {
    final pdf = pw.Document();
    final cleaned = _stripMarkdown(_result ?? '');

    // Collect all links for a separate clickable section
    final allLinks = <MapEntry<String, String>>[];
    final linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    for (final m in linkRegex.allMatches(cleaned)) {
      allLinks.add(MapEntry(m.group(1)!, m.group(2)!));
    }
    // Remove link syntax from body text — show display text only
    final bodyText = cleaned.replaceAllMapped(linkRegex, (m) => m.group(1)!);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(50),
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            text: _docType == 'cv' ? 'Curriculum Vitae' : 'Motivation Letter',
            textStyle: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            widget.studentName,
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.Divider(height: 20, thickness: 0.5),
          // Body content — links stripped to display text only
          ...bodyText.split('\n').map((line) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) return pw.SizedBox(height: 8);
            final isSection = trimmed == trimmed.toUpperCase() && trimmed.length < 50;
            if (isSection) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
                child: pw.Text(trimmed,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                ),
              );
            }
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(trimmed, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.4)),
            );
          }),
          // Clickable links section
          if (allLinks.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Text('Links', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 6),
            ...allLinks.map((link) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.UrlLink(
                destination: link.value,
                child: pw.Text(link.key,
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.blue, decoration: pw.TextDecoration.underline),
                ),
              ),
            )),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = _docType == 'cv'
        ? 'CV_${widget.studentName.replaceAll(' ', '_')}.pdf'
        : 'SOP_${widget.studentName.replaceAll(' ', '_')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _downloadPdf() async {
    try {
      final file = await _generatePdf();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('failedToGeneratePdf').replaceAll('{error}', '$e')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle + header
          _buildHeader(),
          Expanded(
            child: _result != null || _error != null
                ? _buildResult()
                : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(height: 8.h),
        Container(
          width: 40.w, height: 4.h,
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'AI Document Generator',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (!_generating)
                IconButton(
                  icon: Icon(Icons.close, color: const Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doc type selector
          Text(
            'Document Type',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _docTypeBtn('cv', 'CV / Lebenslauf', Icons.person_outline)),
              SizedBox(width: 12.w),
              Expanded(child: _docTypeBtn('sop', 'Motivation Letter', Icons.article_outlined)),
            ],
          ),
          SizedBox(height: 20.h),

          // Student name
          _fieldLabel('Your Name'),
          SizedBox(height: 6.h),
          TextField(
            controller: _nameCtrl,
            style: TextStyle(fontSize: 14.sp),
            decoration: _inputDec('e.g. Ahmed Hassan'),
          ),
          SizedBox(height: 16.h),

          // Background
          _fieldLabel('Your Background'),
          SizedBox(height: 6.h),
          TextField(
            controller: _bgCtrl,
            maxLines: 5,
            style: TextStyle(fontSize: 14.sp),
            decoration: _inputDec(
              'Education, work experience, skills, achievements...',
            ),
          ),
          SizedBox(height: 16.h),

          // Target preview
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16.sp, color: const Color(0xFF3B82F6)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Generated for ${widget.programName} at ${widget.universityName}',
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? SizedBox(
                      width: 18.r, height: 18.r,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                _generating ? 'Generating...' : 'Generate Document',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                disabledBackgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _docTypeBtn(String val, String label, IconData icon) {
    final selected = _docType == val;
    return GestureDetector(
      onTap: _generating ? null : () => setState(() => _docType = val),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3E8FF) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22.sp, color: selected ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8)),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
    );
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14.sp, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
    );
  }

  Future<Uint8List?> _downloadDoc(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await Dio(BaseOptions(
        responseType: ResponseType.bytes,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      )).get(url);
      if (response.statusCode == 200 && response.data is List<int>) {
        return Uint8List.fromList(response.data as List<int>);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('_downloadDoc failed for $url: $e');
    }
    return null;
  }

  // ── generation ──
  Future<void> _generate() async {
    final name = _nameCtrl.text.trim();
    final bg = _bgCtrl.text.trim();
    if (name.isEmpty || bg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('fillNameAndBackground')),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final canUse = await _usageService.canUseGenerator();
    if (!canUse) {
      if (mounted) context.push('/premium');
      return;
    }

    if (!mounted) return;
    setState(() { _generating = true; _result = null; _error = null; });

    try {
      debugPrint('[Generate] Starting generation - docType: ${_docType}');

      // Download attached documents for accurate data extraction
      final docsFuture = Future.wait([
        _downloadDoc(widget.transcriptsUrl),
        _downloadDoc(widget.bachelorCertUrl),
        _downloadDoc(widget.cvUrl),
      ]).timeout(const Duration(seconds: 40));

      final docs = await docsFuture;
      final transcriptPdf = docs[0];
      final bachelorPdf = docs[1];
      final existingCvPdf = docs[2];
      debugPrint('[Generate] Docs downloaded: transcript=${transcriptPdf != null} bachelor=${bachelorPdf != null} cv=${existingCvPdf != null}');

      String result;
      if (_docType == 'cv') {
        result = await _gemini.generateCv(
          programName: widget.programName,
          universityName: widget.universityName,
          major: widget.major,
          studentName: name,
          studentBackground: bg,
          targetDegree: widget.degreeType,
          languageCode: _langCode,
          transcriptPdf: transcriptPdf,
          bachelorCertPdf: bachelorPdf,
          existingCvPdf: existingCvPdf,
        );
      } else {
        result = await _gemini.generateSop(
          programName: widget.programName,
          universityName: widget.universityName,
          degreeType: widget.degreeType,
          major: widget.major,
          studentName: name,
          studentBackground: bg,
          programHighlights: widget.major.isNotEmpty ? 'Focus on $widget.major' : 'General program',
          languageCode: _langCode,
          transcriptPdf: transcriptPdf,
          bachelorCertPdf: bachelorPdf,
          existingCvPdf: existingCvPdf,
        );
      }

      debugPrint('[Generate] Gemini result length: ${result.length}');

      if (result.isNotEmpty) {
        _safeSetState(() { _result = result; _generating = false; });
      } else {
        debugPrint('[Generate] Empty result from Gemini');
        _safeSetState(() {
          _error = 'AI returned empty content. Try again or check your documents.';
          _generating = false;
        });
      }
    } on TimeoutException {
      debugPrint('[Generate] Timed out');
      _safeSetState(() {
        _error = 'Request timed out. Try again with smaller files.';
        _generating = false;
      });
    } on DioException catch (e) {
      debugPrint('[Generate] DioException: $e');
      String msg;
      if (e.response?.statusCode == 429) {
        msg = 'Rate limit reached. Please wait a moment and try again.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        msg = 'Request timed out. Try again with smaller files.';
      } else {
        msg = 'Generation failed. Check your connection and try again.';
      }
      _safeSetState(() { _error = msg; _generating = false; });
    } catch (e, stack) {
      debugPrint('[Generate] Error: $e\n$stack');
      _safeSetState(() {
        _error = 'Generation failed. Check your connection.';
        _generating = false;
      });
    }
  }

  /// Always resets generating state — even if widget is unmounted.
  void _safeSetState(VoidCallback fn) {
    if (mounted) { setState(fn); return; }
    // Widget disposed mid-generation — apply state directly
    // so a fresh mount won't inherit stale "generating=true"
    _generating = false;
    _error = _error ?? 'Generation interrupted. Try again.';
  }

  Widget _buildRichLine(String line) {
    final segments = _parseLine(line);
    // If no links, render as plain text
    if (segments.every((s) => s[0] == false)) {
      return Text(
        segments.map((s) => s[1] as String).join(),
        style: TextStyle(fontSize: 13.sp, color: const Color(0xFF1E293B), height: 1.5),
      );
    }
    // Build RichText with clickable links
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13.sp, color: const Color(0xFF1E293B), height: 1.5),
        children: segments.map((s) {
          if (s[0] == true) {
            final url = s[2] as String;
            return TextSpan(
              text: s[1] as String,
              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
            );
          }
          return TextSpan(text: s[1] as String);
        }).toList(),
      ),
    );
  }

  // ── result display ──
  Widget _buildResult() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: const Color(0xFFEF4444)),
              SizedBox(height: 16.h),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B))),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(AppLocalizations.of(context).translate('retry')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Action bar
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18.sp, color: const Color(0xFF10B981)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _docType == 'cv' ? AppLocalizations.of(context).translate('cvGenerated') : AppLocalizations.of(context).translate('motivationLetterGenerated'),
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
              ),
              _actionBtn(Icons.copy, AppLocalizations.of(context).translate('copy'), () {
                Clipboard.setData(ClipboardData(text: _stripMarkdown(_result!)));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).translate('copiedToClipboard')), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating),
                );
              }),
              SizedBox(width: 6.w),
              _actionBtn(Icons.picture_as_pdf, AppLocalizations.of(context).translate('downloadPdf'), _downloadPdf),
              if (widget.onReplaceFile != null) ...[
                SizedBox(width: 6.w),
                _actionBtn(Icons.cloud_upload, AppLocalizations.of(context).translate('replaceFile'), () async {
                  try {
                    final file = await _generatePdf();
                    widget.onReplaceFile!(file, _docType);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                }),
              ],
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Document content
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in _stripMarkdown(_result!).split('\n'))
                    if (line.trim().isEmpty)
                      SizedBox(height: 8.h)
                    else
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: _buildRichLine(line),
                      ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 18.sp, color: const Color(0xFF8B5CF6)),
      ),
    );
  }
}
