import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/match_score_calculator.dart';
import '../../../data/models/university_model.dart';
import '../../../domain/entities/program_entity.dart';
import '../../../domain/entities/university_entity.dart';
import 'university_search_state.dart';

class UniversitySearchCubit extends Cubit<UniversitySearchState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<UniversityEntity> _cachedUniversities = [];

  String _query = '';
  String _intake = 'All';
  String _degree = 'All';
  String _major = 'All';
  bool _requiresIelts = false;
  bool _acceptsMoi = false;
  double _maxTuition = 20000.0;
  String _language = 'All';
  String _location = 'All';

  List<String> get availableLocations {
    final locs = _cachedUniversities
        .map((u) => u.location)
        .where((l) => l != null && l.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    locs.sort();
    return locs;
  }

  UniversitySearchCubit() : super(UniversitySearchInitial());

  void clearAllFilters() {
    _query = '';
    _intake = 'All';
    _degree = 'All';
    _major = 'All';
    _requiresIelts = false;
    _acceptsMoi = false;
    _maxTuition = 20000.0;
    _language = 'All';
    _location = 'All';
    _applyFilters();
  }

  void updateFilters({
    String? query,
    String? intake,
    String? degree,
    String? major,
    bool? requiresIelts,
    bool? acceptsMoi,
    double? maxTuition,
    String? language,
    String? location,
  }) async {
    if (query != null) _query = query;
    if (intake != null) _intake = intake;
    if (degree != null) _degree = degree;
    if (major != null) _major = major;
    if (requiresIelts != null) _requiresIelts = requiresIelts;
    if (acceptsMoi != null) _acceptsMoi = acceptsMoi;
    if (maxTuition != null) _maxTuition = maxTuition;
    if (language != null) _language = language;
    if (location != null) _location = location;

    if (_cachedUniversities.isEmpty) {
      await _fetchData();
    } else {
      _applyFilters();
    }
  }

  Future<void> _fetchData() async {
    emit(UniversitySearchLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // جلب بيانات الطالب لحساب الـ match scores
      final Map<String, dynamic> profile = (await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()) ?? <String, dynamic>{};

      // جلب الجامعات الموجودة في "ألمانيا" فقط
      final response = await _supabase
          .from('universities')
          .select('*, university_programs(*)')
          .eq('country', 'Germany');

      _cachedUniversities = (response as List).map((json) {
        final uni = UniversityModel.fromJson(
          Map<String, dynamic>.from(json),
        ).toEntity();

        // إعادة حساب matchScore لكل برنامج + matchPercentage للجامعة
        final List<ProgramEntity> recalculatedPrograms = uni.programs.map((p) {
          final int score = MatchScoreCalculator.calculate(
            studentProfile: profile,
            programRequiredGpa: p.requiredGpa,
            programRequiresIelts: p.requiresIelts,
            programMinIelts: p.minIeltsScore,
            programAcceptsMoi: p.acceptsMoi,
            programMajor: p.major,
            programName: p.programName,
            programLanguage: p.instructionLanguage,
            programDegree: p.degreeType,
          );
          return ProgramEntity(
            id: p.id,
            programName: p.programName,
            major: p.major,
            requiredGpa: p.requiredGpa,
            requiresIelts: p.requiresIelts,
            minIeltsScore: p.minIeltsScore,
            acceptsMoi: p.acceptsMoi,
            instructionLanguage: p.instructionLanguage,
            degreeType: p.degreeType,
            deadline: p.deadline,
            applicationFee: p.applicationFee,
            tuitionFeePerYear: p.tuitionFeePerYear,
            curriculum: p.curriculum,
            isRecommended: score >= 60,
            intakeType: p.intakeType,
            matchScore: score,
          );
        }).toList();

        final int maxScore = recalculatedPrograms.isEmpty
            ? 0
            : recalculatedPrograms.map((p) => p.matchScore).reduce(
                  (a, b) => a > b ? a : b,
                );

        return uni.copyWith(
          programs: recalculatedPrograms,
          matchPercentage: maxScore,
        );
      }).toList();

      _applyFilters();
    } catch (e) {
      emit(UniversitySearchError(e.toString()));
    }
  }

  void _applyFilters() {
    final filtered = _cachedUniversities
        .map((uni) {
          final matchedPrograms = uni.programs.where((p) {
            final matchesDegree = _degree == 'All' || _normalizeDegree(p.degreeType) == _degree.toLowerCase();
            final matchesMajor =
                _major == 'All' ||
                p.major.contains(_major) ||
                p.programName.contains(_major);
            final matchesIelts = !_requiresIelts || p.requiresIelts == true;
            final matchesTuition = p.tuitionFeePerYear <= _maxTuition;
            final matchesLang =
                _language == 'All' || p.instructionLanguage == _language;

            // 🎯 فلترة الفصل الدراسي (Intake)
            bool matchesIntake = false;
            if (_intake == 'All' || _intake == 'Both Semesters') {
              matchesIntake = true;
            } else {
              // إذا كان البرنامج "Both" يظهر للجميع، وإلا يجب التطابق
              matchesIntake =
                  p.intakeType == 'Both' || _intake.contains(p.intakeType);
            }

            return matchesDegree &&
                matchesMajor &&
                matchesIelts &&
                matchesTuition &&
                matchesLang &&
                matchesIntake;
          }).toList();

          final matchesLocation = _location == 'All' ||
              (uni.location?.toLowerCase().contains(_location.toLowerCase()) ?? false);
          if (matchedPrograms.isNotEmpty &&
              (_query.isEmpty ||
                  uni.name.toLowerCase().contains(_query.toLowerCase())) &&
              matchesLocation) {
            return uni.copyWith(programs: matchedPrograms);
          }
          return null;
        })
        .whereType<UniversityEntity>()
        .toList();

    emit(
      UniversitySearchLoaded(
        allResults: _cachedUniversities,
        filteredResults: filtered,
        selectedIntake: _intake,
        selectedDegree: _degree,
        selectedMajor: _major,
        requiresIelts: _requiresIelts,
        acceptsMoi: _acceptsMoi,
        maxTuition: _maxTuition,
        selectedLanguage: _language,
        selectedLocation: _location,
      ),
    );
  }

  bool isProgramMatchingFilters(dynamic program) {
    // دالة مساعدة لشاشة الـ UI
    final matchesIntake =
        _intake == 'All' ||
        _intake == 'Both Semesters' ||
        program.intakeType == 'Both' ||
        _intake.contains(program.intakeType);
    return matchesIntake && (program.tuitionFeePerYear <= _maxTuition);
  }

  // تطبيع الـ degree للمقارنة (مطابق لـ MatchScoreCalculator._normalizeDegree)
  String _normalizeDegree(String degree) {
    final d = degree.toLowerCase();
    if (d.contains('bachelor')) return 'bachelor';
    if (d.contains('master')) return 'master';
    if (d.contains('doctor') || d.contains('phd')) return 'doctorate';
    return '';
  }
}
