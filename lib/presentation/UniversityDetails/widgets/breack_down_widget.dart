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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/match_score_calculator.dart';
import '../../../../domain/entities/program_entity.dart';
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

class _ProgramScoreBadgeState extends State<ProgramScoreBadge>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(widget.program.matchScore);
    final bgColor = color.withOpacity(0.1);

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
                Text(
                  '${widget.program.matchScore}% match',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                SizedBox(width: 4.w),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 14.sp,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: _BreakdownContent(program: widget.program),
          ),
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

        final breakdown = MatchScoreCalculator.getBreakdown(
          studentProfile: studentProfile,
          programRequiredGpa: program.requiredGpa,
          programRequiresIelts: program.requiresIelts,
          programMinIelts: program.minIeltsScore,
          programAcceptsMoi: program.acceptsMoi,
          programMajor: program.major,
          programName: program.programName,
          programIntake: program.intakeType,
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
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Score Breakdown',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
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
                      color: _scoreColor(total).withOpacity(0.12),
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
                label: 'GPA',
                score: details['gpa']['score'] as int,
                maxScore: 35,
                hint: _gpaHint(
                  details['gpa']['student_gpa'] as double,
                  details['gpa']['required_gpa'] as double,
                ),
              ),
              _ScoreRow(
                icon: Icons.school_outlined,
                label: 'Field of Study',
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
                label: 'IELTS / Certificate',
                score: details['ielts']['score'] as int,
                maxScore: 15,
                hint: _ieltsHint(details['ielts']),
              ),
              _ScoreRow(
                icon: Icons.language_outlined,
                label: 'Study Language',
                score: details['language']['score'] as int,
                maxScore: 15,
                hint: _langHint(
                  details['language']['student_pref']?.toString() ?? '',
                  details['language']['program_lang']?.toString() ?? '',
                ),
              ),
              _ScoreRow(
                icon: Icons.calendar_today_outlined,
                label: 'Intake Semester',
                score: details['intake']['score'] as int,
                maxScore: 10,
                hint: _intakeHint(
                  details['intake']['student_intake']?.toString() ?? '',
                  details['intake']['program_intake']?.toString() ?? '',
                ),
                isLast: true,
              ),
              if (total < 90) ...[
                Divider(height: 20.h, color: const Color(0xFFE2E8F0)),
                _ImproveTip(breakdownDetails: details),
              ],
            ],
          ),
        );
      },
    );
  }

  String _gpaHint(double studentGpa, double requiredGpa) {
    if (studentGpa <= 0) return 'GPA not set in your profile';
    final diff = studentGpa - requiredGpa;
    if (diff >= 0)
      return 'Your GPA ($studentGpa) meets the requirement ($requiredGpa) ✓';
    if (diff >= -0.2)
      return 'Your GPA is $studentGpa — just ${diff.abs().toStringAsFixed(1)} below the required $requiredGpa';
    if (diff >= -0.5)
      return 'Your GPA is $studentGpa — required is $requiredGpa (conditional admission possible)';
    return 'Your GPA ($studentGpa) is below the required $requiredGpa';
  }

  String _majorHint(String student, String program, int score) {
    if (score == 25)
      return '"$student" matches this program\'s major exactly ✓';
    if (score == 18)
      return 'Related field — "$student" is in the same category as "$program"';
    if (score > 0) return 'Partial match between "$student" and "$program"';
    return 'Your field "$student" doesn\'t match "$program"';
  }

  String _ieltsHint(Map<String, dynamic> ielts) {
    final bool req = ielts['requires_ielts'] as bool? ?? false;
    final double min = (ielts['min_ielts'] as num?)?.toDouble() ?? 0;
    final double yours = (ielts['student_ielts'] as num?)?.toDouble() ?? 0;
    final int score = ielts['score'] as int;

    if (!req) return 'This program doesn\'t require IELTS';
    if (score == 15) return 'Your IELTS ($yours) meets the minimum ($min) ✓';
    if (score == 10) return 'Accepted via MOI certificate ✓';
    if (score == 8)
      return 'Your IELTS ($yours) is slightly below the required $min';
    if (yours > 0) return 'Your IELTS ($yours) is below the required $min';
    return 'This program requires IELTS ($min+) — add your score in Settings';
  }

  String _langHint(String student, String program) {
    if (student.toLowerCase() == 'both')
      return 'You\'re open to both languages ✓';
    if (student.toLowerCase() == program.toLowerCase()) {
      return 'Program is taught in ${program.toUpperCase()} — matches your preference ✓';
    }
    return 'Program is in $program — your preference is $student';
  }

  String _intakeHint(String student, String program) {
    final ns = _normalizeIntake(student);
    final np = _normalizeIntake(program);
    if (np == 'both' || ns == 'both') return 'Both intakes available ✓';
    if (ns == np) return 'Intake matches your target semester ✓';
    return 'Program intake is $program — you\'re targeting $student';
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
// _ScoreRow
// ─────────────────────────────────────────────────────────
class _ScoreRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int score;
  final int maxScore;
  final String hint;
  final bool isLast;

  const _ScoreRow({
    required this.icon,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.hint,
    this.isLast = false,
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
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.sp, color: const Color(0xFF64748B)),
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
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
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
    final intake = breakdownDetails['intake']['score'] as int;

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

    if (intake < 10) {
      final String progIntake =
          breakdownDetails['intake']['program_intake']?.toString() ?? '';
      return 'This program only accepts $progIntake intake. Update your target semester in Settings.';
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
      return 'This program requires a GPA of $req. A conditional admission might still be possible — contact the university.';
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16.sp, color: const Color(0xFF94A3B8)),
          SizedBox(width: 8.w),
          // ✅ Expanded يمنع الـ overflow
          Expanded(
            child: Text(
              'Complete your profile in Settings to see the full breakdown.',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────
Color _scoreColor(int score) {
  if (score >= 75) return const Color(0xFF10B981);
  if (score >= 50) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}
