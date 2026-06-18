// ====================
// FILE: lib/presentation/UniversityDetails/widgets/breack_down_widget.dart
// ====================
//
// الـ Fixes:
//  🐛 Fix #1 — Overflow في _SimpleScoreDisplay
//     الـ Text مكانش ملفوف بـ Expanded فكان بيتجاوز الـ Row
//     ✅ لففنا الـ Text بـ Expanded
//
//  🐛 Fix #2 — بعض الـ Wikimedia SVG logos بترجع 400
//     ده مش في الـ widget — الـ widget بيعرض errorWidget صح
//     لكن الـ _SimpleScoreDisplay overflow كان بيخفي ده

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/ai/ai_usage_service.dart';
import '../../../../core/services/ai/gemini_service.dart';
import '../../../../core/services/ai/review_cache_service.dart';
import '../../../../core/services/services_locator.dart';
import '../../../../core/utils/match_score_calculator.dart';
import '../../../../core/utils/missing_doc_templates.dart';
import '../../../../core/widgets/animated_match_score.dart';
import '../../../../domain/entities/program_entity.dart';
import '../../../../domain/entities/university_entity.dart';
import '../../ai/widgets/ai_document_generator.dart';
import '../../ai/widgets/ai_document_review_sheet.dart';
import '../../ai/widgets/ai_suggestion_button.dart';
import '../cubit/university_details_cubit.dart';
import '../cubit/university_details_state.dart';

// ─────────────────────────────────────────────────────────
// ProgramScoreBadge — بيتحط في الـ ProgramCard
// ─────────────────────────────────────────────────────────
class ProgramScoreBadge extends StatefulWidget {
  final ProgramEntity program;

  const ProgramScoreBadge({super.key, required this.program});

  @override
  State<ProgramScoreBadge> createState() => _ProgramScoreBadgeState();
}

class _ProgramScoreBadgeState extends State<ProgramScoreBadge> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(widget.program.matchScore);
    final bgColor = color.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 13.sp, color: color),
                SizedBox(width: 3.w),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScoreText(
                      score: widget.program.matchScore,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      ' match',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 14.sp,
                  color: color,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: _BreakdownContent(program: widget.program),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// _BreakdownContent
// ─────────────────────────────────────────────────────────
class _BreakdownContent extends StatelessWidget {
  final ProgramEntity program;

  const _BreakdownContent({required this.program});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityDetailsCubit, UniversityDetailsState>(
      builder: (context, state) {
        Map<String, dynamic>? studentProfile;
        if (state is UniversitySaveStatus) {
          studentProfile = state.studentProfile;
        }

        if (studentProfile == null) {
          return _SimpleScoreDisplay(score: program.matchScore);
        }

        final status = state as UniversitySaveStatus;
        final breakdown = MatchScoreCalculator.getBreakdown(
          studentProfile: studentProfile,
          programRequiredGpa: program.requiredGpa,
          programRequiresIelts: program.requiresIelts,
          programMinIelts: program.minIeltsScore,
          programAcceptsMoi: program.acceptsMoi,
          programMajor: program.major,
          programName: program.programName,
          programIntake: program.intakeType, // informational only
          programLanguage: program.instructionLanguage,
          programDegree: program.degreeType,
        );

        final Map<String, dynamic> details =
            breakdown['breakdown'] as Map<String, dynamic>;
        final int total = breakdown['total'] as int;
        final String label = breakdown['label'] as String;

        return Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).translate('matchScore'),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: _scoreColor(total).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '$total% · $label',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _scoreColor(total),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _ScoreRow(
                icon: Icons.grade_outlined,
                label: AppLocalizations.of(context).translate('gpa'),
                score: details['gpa']['score'] as int,
                maxScore: 35,
                hint: _gpaHint(
                  details['gpa']['student_gpa'] as double,
                  details['gpa']['required_gpa'] as double,
                ),
              ),
              _ScoreRow(
                icon: Icons.school_outlined,
                label: AppLocalizations.of(context).translate('major'),
                score: details['major']['score'] as int,
                maxScore: 25,
                hint: _majorHint(
                  details['major']['student_major']?.toString() ?? '',
                  details['major']['program_major']?.toString() ?? '',
                  details['major']['score'] as int,
                ),
              ),
              _ScoreRow(
                icon: Icons.translate_outlined,
                label: AppLocalizations.of(context).translate('ielts'),
                score: details['ielts']['score'] as int,
                maxScore: 15,
                hint: _ieltsHint(details['ielts']),
              ),
              _ScoreRow(
                icon: Icons.language_outlined,
                label: AppLocalizations.of(context).translate('languageOfInstruction'),
                score: details['language']['score'] as int,
                maxScore: 15,
                hint: _langHint(
                  details['language']['student_pref']?.toString() ?? '',
                  details['language']['program_lang']?.toString() ?? '',
                ),
              ),
              _ScoreRow(
                icon: Icons.description_outlined,
                label: 'Documents',
                score: details['completeness']['score'] as int,
                maxScore: 10,
                hint: _completenessHint(details['completeness'] as Map<String, dynamic>),
              ),
              _IntakeRow(
                studentIntake: details['intake']['student_intake']?.toString() ?? '',
                programIntake: details['intake']['program_intake']?.toString() ?? '',
              ),
              if (total < 100) ...[
                Divider(height: 20.h, color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                _ImproveTip(breakdownDetails: details),
              ],
              SizedBox(height: 12.h),
              _AiImproveButton(
                studentProfile: studentProfile,
                programDetails: {
                  'name': program.programName,
                  'major': program.major,
                  'degree': program.degreeType,
                  'required_gpa': program.requiredGpa,
                  'requires_ielts': program.requiresIelts,
                  'min_ielts': program.minIeltsScore,
                  'accepts_moi': program.acceptsMoi,
                  'language': program.instructionLanguage,
                  'intake': program.intakeType,
                },
                breakdown: details,
              ),
              SizedBox(height: 8.h),
              _AiDocReviewButton(
                studentProfile: studentProfile,
                currentUniversity: status.currentUniversity,
                programDetails: {
                  'name': program.programName,
                  'major': program.major,
                  'degree': program.degreeType,
                  'required_gpa': program.requiredGpa,
                  'requires_ielts': program.requiresIelts,
                  'min_ielts': program.minIeltsScore,
                  'accepts_moi': program.acceptsMoi,
                  'language': program.instructionLanguage,
                  'intake': program.intakeType,
                },
                uploadStatus: {
                  'has_transcripts':
                      status.currentUniversity?.hasTranscripts is String,
                  'has_bachelor_cert':
                      status.currentUniversity?.hasBachelorCert is String,
                  'has_sop': status.currentUniversity?.hasSop is String,
                  'has_cv': status.currentUniversity?.hasCv is String,
                  'has_language_cert':
                      status.currentUniversity?.hasLanguageCert is String,
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _gpaHint(double germanGpa, double requiredGpa) {
    if (germanGpa <= 0) {
      return 'GPA not set in your profile';
    }
    if (requiredGpa <= 0) {
      // البرنامج معندهوش متطلب GPA — مجرد عرض الـ German GPA
      if (germanGpa <= 2.5) {
        return 'Your German GPA ($germanGpa) is competitive for German universities ✓';
      }
      return 'Your German GPA ($germanGpa) — improving it would increase your match score.';
    }
    // German GPA: lower = better. Student ≤ required → meets.
    if (germanGpa <= requiredGpa) {
      return 'Your German GPA ($germanGpa) meets the requirement ($requiredGpa) ✓';
    }
    final double diff = germanGpa - requiredGpa;
    if (diff <= 0.2) {
      return 'Your German GPA ($germanGpa) is just ${diff.toStringAsFixed(1)} above the required $requiredGpa';
    }
    if (diff <= 0.5) {
      return 'Your German GPA ($germanGpa) — required is $requiredGpa (conditional admission possible)';
    }
    return 'Your German GPA ($germanGpa) is below the required $requiredGpa';
  }

  String _majorHint(String student, String program, int score) {
    if (score == 25) {
      return '"$student" matches this program\'s major exactly ✓';
    }
    if (score == 10) {
      return '"$student" is in the same broad category as "$program"';
    }
    if (score == 5) {
      return 'Weak partial match between "$student" and "$program"';
    }
    return 'Your field "$student" doesn\'t match "$program"';
  }

  String _ieltsHint(Map<String, dynamic> ielts) {
    final bool req = ielts['requires_ielts'] as bool? ?? false;
    final double min = (ielts['min_ielts'] as num?)?.toDouble() ?? 0;
    final double yours = (ielts['student_ielts'] as num?)?.toDouble() ?? 0;
    final int score = ielts['score'] as int;

    if (!req) {
      return 'This program doesn\'t require IELTS';
    }
    if (score == 15) {
      return 'Your IELTS ($yours) meets the minimum ($min) ✓';
    }
    if (score == 10) {
      return 'Accepted via MOI certificate ✓';
    }
    if (score == 8) {
      return 'Your IELTS ($yours) is slightly below the required $min';
    }
    if (yours > 0) {
      return 'Your IELTS ($yours) is below the required $min';
    }
    return 'This program requires IELTS ($min+) — add your score in Settings';
  }

  String _langHint(String student, String program) {
    if (student.toLowerCase() == 'both') {
      return 'You\'re open to both languages ✓';
    }
    if (student.toLowerCase() == program.toLowerCase()) {
      return 'Program is taught in ${program.toUpperCase()} — matches your preference ✓';
    }
    return 'Program is in $program — your preference is $student';
  }

  String _completenessHint(Map<String, dynamic> completeness) {
    final missing = <String>[];
    if (completeness['has_transcripts'] != true) missing.add('Transcripts');
    if (completeness['has_bachelor_cert'] != true) missing.add('Bachelor Cert');
    if (completeness['has_sop'] != true) missing.add('SOP');
    if (completeness['has_cv'] != true) missing.add('CV');
    if (missing.isEmpty) return 'All documents ready ✓';
    return 'Missing: ${missing.join(', ')}';
  }
}

// ─────────────────────────────────────────────────────────
// _ScoreRow
// ─────────────────────────────────────────────────────────
class _ScoreRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int score;
  final int maxScore;
  final String hint;

  const _ScoreRow({
    required this.icon,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = score / maxScore;
    final Color barColor = pct >= 0.8
        ? const Color(0xFF10B981)
        : pct >= 0.5
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              Text(
                '$score/$maxScore',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: barColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _IntakeRow — compatibility indicator (no points)
// ─────────────────────────────────────────────────────────
class _IntakeRow extends StatelessWidget {
  final String studentIntake;
  final String programIntake;

  const _IntakeRow({
    required this.studentIntake,
    required this.programIntake,
  });

  @override
  Widget build(BuildContext context) {
    final ns = _normalizeIntake(studentIntake);
    final np = _normalizeIntake(programIntake);
    final bool compatible = np == 'both' || ns == 'both' || ns == np;

    final Color bgColor = compatible
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEE2E2);
    final Color fgColor = compatible
        ? const Color(0xFF065F46)
        : const Color(0xFF991B1B);
    final IconData icon = compatible
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 15.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              'Intake',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13.sp, color: fgColor),
                SizedBox(width: 4.w),
                Text(
                  compatible
                      ? 'Compatible'
                      : '${_capitalize(np)} only',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _normalizeIntake(String i) {
    i = i.toLowerCase();
    if (i.contains('both')) return 'both';
    if (i.contains('summer')) return 'Summer';
    if (i.contains('winter')) return 'Winter';
    return i;
  }
}

// ─────────────────────────────────────────────────────────
// _ImproveTip
// ─────────────────────────────────────────────────────────
class _ImproveTip extends StatelessWidget {
  final Map<String, dynamic> breakdownDetails;

  const _ImproveTip({required this.breakdownDetails});

  @override
  Widget build(BuildContext context) {
    final tip = _buildTip();
    if (tip == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            size: 15.sp,
            color: const Color(0xFF3B82F6),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF1D4ED8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _buildTip() {
    final gpa = breakdownDetails['gpa']['score'] as int;
    final ielts = breakdownDetails['ielts']['score'] as int;
    final major = breakdownDetails['major']['score'] as int;
    final lang = breakdownDetails['language']['score'] as int;
    final compl = breakdownDetails['completeness']['score'] as int;
    final complMap = breakdownDetails['completeness'] as Map<String, dynamic>;
    final String studentIntake =
        breakdownDetails['intake']['student_intake']?.toString() ?? '';
    final String programIntake =
        breakdownDetails['intake']['program_intake']?.toString() ?? '';

    if (ielts < 15) {
      final bool req =
          breakdownDetails['ielts']['requires_ielts'] as bool? ?? false;
      final double min =
          (breakdownDetails['ielts']['min_ielts'] as num?)?.toDouble() ?? 0;
      if (!req) return null;
      if (ielts == 0) {
        return 'Adding an IELTS score of $min+ would add +15 pts to your match score.';
      }
      final double yours =
          (breakdownDetails['ielts']['student_ielts'] as num?)?.toDouble() ?? 0;
      return 'Improving your IELTS from $yours to $min would add +${15 - ielts} pts.';
    }

    if (lang < 15) {
      final String progLang =
          breakdownDetails['language']['program_lang']?.toString() ?? '';
      return 'Set your language preference to "$progLang" or "Both" in Settings to gain +${15 - lang} pts.';
    }

    if (major < 25) {
      return 'Your field of study is a partial match. Consider updating it in Settings for a more accurate score.';
    }

    if (gpa < 15) {
      final double req =
          (breakdownDetails['gpa']['required_gpa'] as num?)?.toDouble() ?? 0;
      if (req > 0) {
        return 'This program requires a GPA of $req. A conditional admission might still be possible — contact the university.';
      }
      return 'Improving your GPA would significantly increase your match score for this program.';
    }

    // Intake tip (informational only, lowest priority)
    if (programIntake.isNotEmpty && studentIntake.isNotEmpty) {
      final ns = studentIntake.toLowerCase().contains('both') ? 'both'
          : studentIntake.toLowerCase().contains('summer') ? 'summer'
          : studentIntake.toLowerCase().contains('winter') ? 'winter'
          : studentIntake;
      final np = programIntake.toLowerCase().contains('both') ? 'both'
          : programIntake.toLowerCase().contains('summer') ? 'summer'
          : programIntake.toLowerCase().contains('winter') ? 'winter'
          : programIntake;
      final bool compatible = np == 'both' || ns == 'both' || ns == np;
      if (!compatible) {
        return 'This program runs in $programIntake — your target is $studentIntake. Consider updating your intake preference.';
      }
    }

    // Completeness tip (lowest priority — user may not have uploaded yet)
    if (compl < 10) {
      final missing = <String>[];
      if (complMap['has_transcripts'] != true) missing.add('Transcripts');
      if (complMap['has_bachelor_cert'] != true) missing.add('Bachelor Cert');
      if (complMap['has_sop'] != true) missing.add('SOP');
      if (complMap['has_cv'] != true) missing.add('CV');
      return 'Upload ${missing.join(", ")} in My Documents to add +${10 - compl} pts to your match score.';
    }

    return null;
  }
}

// ─────────────────────────────────────────────────────────
// ✅ Fix #1 — _SimpleScoreDisplay
// الـ Text الآن ملفوف بـ Expanded عشان ميتجاوزش الـ Row
// ─────────────────────────────────────────────────────────
class _SimpleScoreDisplay extends StatelessWidget {
  final int score;
  const _SimpleScoreDisplay({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16.sp, color: AppColors.textMuted),
          SizedBox(width: 8.w),
          // ✅ Expanded يمنع الـ overflow
          Expanded(
            child: Text(
              'Complete your profile in Settings to see the full breakdown.',
              style: TextStyle(fontSize: 12.sp, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _AiImproveButton — AI suggestion button per program
// ─────────────────────────────────────────────────────────
class _AiImproveButton extends StatefulWidget {
  final Map<String, dynamic> studentProfile;
  final Map<String, dynamic> programDetails;
  final Map<String, dynamic> breakdown;

  const _AiImproveButton({
    required this.studentProfile,
    required this.programDetails,
    required this.breakdown,
  });

  @override
  State<_AiImproveButton> createState() => _AiImproveButtonState();
}

class _AiImproveButtonState extends State<_AiImproveButton> {

  Future<void> _showAiSuggestions() async {
    // 💎 Premium feature
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context).translate('premiumFeature')),
          content: Text(AppLocalizations.of(context).translate('premiumDescription')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AiSuggestionButton(
      label: AppLocalizations.of(context).translate('aiTips'),
      onPressed: _showAiSuggestions,
    );
  }
}

// ─────────────────────────────────────────────────────────
// _AiDocReviewButton — AI document review per program
// ─────────────────────────────────────────────────────────
class _AiDocReviewButton extends StatefulWidget {
  final Map<String, dynamic> studentProfile;
  final UniversityEntity? currentUniversity;
  final Map<String, dynamic> programDetails;
  final Map<String, dynamic> uploadStatus;

  const _AiDocReviewButton({
    required this.studentProfile,
    required this.currentUniversity,
    required this.programDetails,
    required this.uploadStatus,
  });

  @override
  State<_AiDocReviewButton> createState() => _AiDocReviewButtonState();
}

class _AiDocReviewButtonState extends State<_AiDocReviewButton> {
  final _gemini = sl<GeminiService>();
  final _usageService = sl<AiUsageService>();
  final _cacheService = sl<ReviewCacheService>();
  int _remainingUses = 0;

  String get _langCode =>
      sl<LanguageProvider>().locale.languageCode;

  @override
  void initState() {
    super.initState();
    _loadRemaining();
  }

  Future<void> _loadRemaining() async {
    final remaining = await _usageService.getRemainingUses();
    if (mounted) setState(() => _remainingUses = remaining);
  }

  Future<void> _reviewDocuments() async {
    final local = AppLocalizations.of(context);
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

    // التحقق من وجود ملفات مرفوعة قبل التحليل
    final uni = widget.currentUniversity;
    final hasAnyDoc = [
      uni?.hasTranscripts,
      uni?.hasBachelorCert,
      uni?.hasSop,
      uni?.hasCv,
      uni?.hasLanguageCert,
    ].any((url) => url is String && url.startsWith('http'));

    if (!hasAnyDoc) {
      if (mounted) {
        Navigator.pop(context); // إغلاق أي bottom sheet مفتوح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('noDocumentsUploaded')),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

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
      final programName = widget.programDetails['name']?.toString() ?? '';
      int validReviewCount = 0;

      final docConfigs = [
        ('has_transcripts', 'Academic Transcripts', 'transcripts'),
        ('has_bachelor_cert', 'Bachelor Certificate', 'bachelor_cert'),
        ('has_sop', 'SOP / Motivation Letter', 'sop'),
        ('has_cv', 'CV / Resume', 'cv'),
        ('has_language_cert', 'Language Certificate', 'language_cert'),
      ];

      for (int i = 0; i < docConfigs.length; i++) {
        final (col, title, docType) = docConfigs[i];
        stepLabel = 'Downloading ${i + 1}/${docConfigs.length} — $title';
        updateSheet(() {});

        // Read URL from currentUniversity entity (fresh after uploads)
        String? url;
        switch (col) {
          case 'has_transcripts':
            url = uni?.hasTranscripts;
            break;
          case 'has_bachelor_cert':
            url = uni?.hasBachelorCert;
            break;
          case 'has_sop':
            url = uni?.hasSop;
            break;
          case 'has_cv':
            url = uni?.hasCv;
            break;
          case 'has_language_cert':
            url = uni?.hasLanguageCert;
            break;
        }

        if (url is String && url.startsWith('http')) {
          // Check cache first
          final cached = await _cacheService.getCachedReview(
            docType: docType,
            currentUrl: url,
          );
          if (cached != null) {
            allReviews.add({
              'doc_type': docType,
              'title': title,
              'status': 'uploaded',
              'tips': cached
                  .map((r) => r['suggestion']?.toString() ?? '')
                  .toList(),
              'importance': cached.isNotEmpty
                  ? cached
                      .map((r) => r['severity']?.toString() ?? 'medium')
                      .fold<String>(
                          'medium', (a, b) => b == 'high' ? 'high' : a)
                  : 'medium',
              '_program_name': programName,
            });
            stepLabel = '${local.translate('cachedLabel')} ${i + 1}/${docConfigs.length} — $title';
            updateSheet(() {});
            await Future.delayed(const Duration(milliseconds: 300));
            continue;
          }

          try {
            stepLabel = '${local.translate('downloadLabel')} ${i + 1}/${docConfigs.length} — $title';
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
                  await Future.delayed(
                      Duration(seconds: 2 * (attempt + 1)));
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
                      ? local.translate('serverReturned').replaceAll('{code}', response.statusCode.toString())
                      : local.translate('couldNotDownload'),
                ],
                'importance': 'medium',
                '_program_name': programName,
              });
              continue;
            }

            stepLabel = '${local.translate('analyzeLabel')} ${i + 1}/${docConfigs.length} — $title';
            updateSheet(() {});

            if (i > 0) await Future.delayed(const Duration(seconds: 2));

            final mimeType = response.headers.value('content-type') ?? 'application/pdf';
            final reviews = await _gemini.reviewDocumentWithPdf(
              studentProfile: widget.studentProfile,
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
                    ? local.translate('serverReturned').replaceAll('{code}', e.response?.statusCode.toString() ?? '')
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
              'tips': [local.translate('aiFailed').replaceAll('{error}', e.toString())],
              'importance': 'medium',
              '_program_name': programName,
            });
          }
        } else {
          stepLabel = '${local.translate('recommendationsLabel')} ${i + 1}/${docConfigs.length} — $title';
          updateSheet(() {});

          final staticSuggestions =
              MissingDocTemplates.getSuggestions(widget.studentProfile);
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
        _showResults(allReviews);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showResults([],
            error: local.translate('reviewFailed'));
      }
    }
  }

  void _showResults(List<Map<String, dynamic>> reviews, {String? error}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiDocumentReviewSheet(
        reviews: reviews,
        error: error,
        onRetry: error != null ? _reviewDocuments : null,
        onGenerateDocument: (ctx, docType, programName) {
          Navigator.pop(ctx);
          _openGenerator(ctx, docType, programName);
        },
      ),
    );
  }

  void _openGenerator(BuildContext ctx, String docType, String programName) {
    final studentProfile = widget.studentProfile;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenerateSheet(
        programName:
            programName.isNotEmpty ? programName : 'German University Program',
        universityName: '', // not available here, pass empty
        degreeType: widget.programDetails['degree']?.toString() ?? '',
        major: widget.programDetails['major']?.toString() ?? '',
        studentName: studentProfile['username']?.toString() ?? '',
        studentBackground:
            'GPA: ${studentProfile['gpa'] ?? 'N/A'}, Target: ${studentProfile['target_major'] ?? 'N/A'}, IELTS: ${studentProfile['ielts_score'] ?? 'N/A'}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AiSuggestionButton(
      label: AppLocalizations.of(context).translate('aiReview'),
      onPressed: _reviewDocuments,
      remainingUses: _remainingUses,
    );
  }
}

// ─────────────────────────────────────────────────────────
// _ReviewProgressSheet — loading indicator with step label
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

    // Draw 4 diamond sparkles rotating
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

    // Center dot
    canvas.drawCircle(center, 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────
Color _scoreColor(int score) {
  if (score >= 75) return const Color(0xFF10B981);
  if (score >= 50) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}
