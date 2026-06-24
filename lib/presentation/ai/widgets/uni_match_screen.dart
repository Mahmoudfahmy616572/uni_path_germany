import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/ai/gemini_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/university_model.dart';
import '../../../domain/repositories/applications_repository.dart';
import '../../MyApplications/cubit/my_applications_cubits.dart';
import '../../MyApplications/cubit/my_applications_states.dart';

class _ProgramRef {
  final String universityId;
  final String universityName;
  final String location;
  final String programId;
  final String programName;
  final String degree;
  final String? deadline;
  final double? requiredGpa;
  final bool requiresIelts;

  const _ProgramRef({
    required this.universityId,
    required this.universityName,
    required this.location,
    required this.programId,
    required this.programName,
    required this.degree,
    this.deadline,
    this.requiredGpa,
    this.requiresIelts = false,
  });
}

class UniMatchScreen extends StatefulWidget {
  const UniMatchScreen({super.key});

  @override
  State<UniMatchScreen> createState() => _UniMatchScreenState();
}

class _UniMatchScreenState extends State<UniMatchScreen> {
  final _gemini = sl<GeminiService>();
  final _repo = sl<ApplicationsRepository>();
  static List<Map<String, dynamic>>? _cached;
  List<Map<String, dynamic>>? _recommendations;
  Set<String> _savedKeys = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_cached != null) {
      _recommendations = _cached;
      return;
    }
    _loadRecommendations();
  }

  String _resultKey(Map<String, dynamic> r) =>
      '${r['_universityId']}_${r['_programId']}';

  Future<void> _loadRecommendations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await Supabase.instance.client
          .from('profiles').select().eq('id', userId).maybeSingle();
      if (!mounted) return;
      if (profile == null) {
        setState(() { _error = 'Please complete your profile first'; _loading = false; });
        return;
      }

      // Fetch all universities + programs for name matching later
      final supabase = Supabase.instance.client;
      final uniResponse = await supabase
          .from('universities')
          .select('*, university_programs(*)')
          .eq('country', 'Germany');

      final allUnis = (uniResponse as List).map((json) =>
          UniversityModel.fromJson(Map<String, dynamic>.from(json)).toEntity()
      ).toList();

      final refs = <_ProgramRef>[];
      for (final uni in allUnis) {
        for (final prog in uni.programs) {
          refs.add(_ProgramRef(
            universityId: uni.id,
            universityName: uni.name,
            location: uni.location ?? '',
            programId: prog.id,
            programName: prog.programName,
            degree: prog.degreeType,
            deadline: prog.deadline,
            requiredGpa: prog.requiredGpa,
            requiresIelts: prog.requiresIelts,
          ));
        }
      }

      try {
        if (!mounted) return;
        final appsState = context.read<MyApplicationsCubit>().state;
        if (appsState is MyApplicationsLoaded) {
          final saved = <String>{};
          for (final u in appsState.allApplications) {
            for (final p in u.programs) {
              saved.add('${u.id}_${p.id}');
            }
          }
          _savedKeys = saved;
        }
      } catch (_) {}

      // Call Gemini WITHOUT the huge program list — prompt stays small & fast
      final result = await _gemini.getUniversityRecommendations(
        studentProfile: profile,
      );

      // Match each result to a _ProgramRef by university + program name
      final matched = <Map<String, dynamic>>[];
      for (final r in result) {
        final uniName = (r['university'] as String?)?.trim().toLowerCase() ?? '';
        final progName = (r['program'] as String?)?.trim().toLowerCase() ?? '';

        _ProgramRef? match;
        for (final ref in refs) {
          if (ref.universityName.toLowerCase() == uniName &&
              ref.programName.toLowerCase() == progName) {
            match = ref;
            break;
          }
        }
        if (match == null) {
          for (final ref in refs) {
            if (ref.universityName.toLowerCase().contains(uniName) &&
                ref.programName.toLowerCase().contains(progName)) {
              match = ref;
              break;
            }
          }
        }
        if (match != null) {
          r['_universityId'] = match.universityId;
          r['_programId'] = match.programId;
        }
        matched.add(r);
      }

      if (mounted) {
        _cached = matched;
        setState(() { _recommendations = matched; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleSave(Map<String, dynamic> r) async {
    final key = _resultKey(r);
    final isSaved = _savedKeys.contains(key);
    final uniId = r['_universityId'] as String?;
    final progId = r['_programId'] as String?;
    if (uniId == null || progId == null) return;

    try {
      if (isSaved) {
        await _repo.removeSavedProgram(universityId: uniId, programId: progId);
        setState(() => _savedKeys.remove(key));
      } else {
        await _repo.saveProgram(universityId: uniId, programId: progId);
        setState(() => _savedKeys.add(key));
      }
      sl<MyApplicationsCubit>().loadApplications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSaved ? 'Removed from Pipeline' : 'Added to Pipeline'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('AI University Match')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                        SizedBox(height: 16.h),
                        Text('Could not load recommendations', style: TextStyle(fontSize: 16.sp)),
                        if (_error != null) ...[
                          SizedBox(height: 8.h),
                          Text(_error!, style: TextStyle(fontSize: 11.sp, color: Colors.red.shade700), textAlign: TextAlign.center),
                        ],
                        SizedBox(height: 16.h),
                        ElevatedButton(onPressed: _loadRecommendations, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _recommendations == null || _recommendations!.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_outlined, size: 48.sp, color: const Color(0xFF94A3B8)),
                            SizedBox(height: 16.h),
                            Text('Complete your profile to get matches',
                                style: TextStyle(fontSize: 16.sp,
                                    color: isDark ? AppColors.textMuted : const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.r),
                      itemCount: _recommendations!.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildHeader(isDark);
                        final r = _recommendations![index - 1];
                        return _buildCard(r, isDark);
                      },
                    ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Top Matches',
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                Text('Tap the checkmark to save a program to your Pipeline',
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r, bool isDark) {
    final score = (r['matchScore'] as num?)?.toInt() ?? 0;
    final color = score >= 80 ? const Color(0xFF16A34A) : score >= 60 ? const Color(0xFFD97706) : const Color(0xFFDC2626);
    final hasIds = r['_universityId'] != null && r['_programId'] != null;
    final isSaved = hasIds && _savedKeys.contains(_resultKey(r));

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSaved
              ? const Color(0xFFBBF7D0)
              : isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r['university'] ?? ''}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp,
                            color: isDark ? AppColors.textMain : const Color(0xFF0F172A))),
                    SizedBox(height: 2.h),
                    Text('${r['program'] ?? ''} • ${r['degree'] ?? ''}',
                        style: TextStyle(fontSize: 13.sp,
                            color: isDark ? AppColors.textMuted : const Color(0xFF4F46E5))),
                    SizedBox(height: 2.h),
                    Text('${r['location'] ?? ''}',
                        style: TextStyle(fontSize: 12.sp,
                            color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$score%',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    ),
                  ),
                  if (hasIds) ...[
                    SizedBox(height: 6.h),
                    GestureDetector(
                      onTap: () => _toggleSave(r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: isSaved ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved ? Icons.check_circle : Icons.add_circle_outline,
                          size: 20.r,
                          color: isSaved ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _ExpandableReason(text: '${r['reason'] ?? ''}'),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.description_outlined, size: 14.r, color: const Color(0xFF94A3B8)),
              SizedBox(width: 4.w),
              Expanded(
                child: Text('${r['requirements'] ?? ''}',
                    style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
              ),
            ],
          ),
          if (r['deadline'] != null && (r['deadline'] as String).isNotEmpty) ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14.r, color: const Color(0xFF94A3B8)),
                SizedBox(width: 4.w),
                Text('Deadline: ${r['deadline']}',
                    style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
              ],
            ),
          ],
          if (hasIds) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleSave(r),
                  icon: Icon(
                    isSaved ? Icons.check_circle : Icons.add_circle_outline,
                    size: 16,
                    color: isSaved ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                  ),
                  label: Text(
                    isSaved ? 'Added to Pipeline' : 'Add to Pipeline',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isSaved ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandableReason extends StatefulWidget {
  final String text;
  const _ExpandableReason({required this.text});

  @override
  State<_ExpandableReason> createState() => _ExpandableReasonState();
}

class _ExpandableReasonState extends State<_ExpandableReason> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(
      fontSize: 12.sp,
      height: 1.4,
      color: isDark ? AppColors.textMuted : const Color(0xFF475569),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Text(widget.text, style: textStyle, maxLines: 3, overflow: TextOverflow.clip),
            secondChild: Text(widget.text, style: textStyle),
          ),
        ),
        if (widget.text.length > 120)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                _expanded ? 'Show less' : 'Show more',
                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w500),
              ),
            ),
          ),
      ],
    );
  }
}
