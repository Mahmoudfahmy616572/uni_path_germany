import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  const GenerateSheet({
    super.key,
    required this.programName,
    required this.universityName,
    required this.degreeType,
    required this.major,
    required this.studentName,
    required this.studentBackground,
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
            child: _result != null
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
                      width: 18, height: 18,
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

  // ── generation ──
  Future<void> _generate() async {
    final name = _nameCtrl.text.trim();
    final bg = _bgCtrl.text.trim();
    if (name.isEmpty || bg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in your name and background.'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final canUse = await _usageService.canUseAi();
    if (!canUse) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Monthly limit reached (10 uses). Upgrade for unlimited!'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _usageService.showRemainingUses(context);

    setState(() { _generating = true; _result = null; _error = null; });

    try {
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
        );
      }

      if (result.isNotEmpty) {
        await _usageService.recordUsage();
      }

      if (mounted) setState(() { _result = result; _generating = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Generation failed. Check your connection.';
          _generating = false;
        });
      }
    }
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
                label: const Text('Retry'),
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
                  _docType == 'cv' ? 'CV Generated' : 'Motivation Letter Generated',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
              ),
              _actionBtn(Icons.copy, 'Copy', () {
                Clipboard.setData(ClipboardData(text: _result!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Copied to clipboard!'), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating),
                );
              }),
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
              child: SelectableText(
                _result!,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF1E293B),
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
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
