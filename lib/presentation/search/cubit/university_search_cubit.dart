import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/match_score_calculator.dart';
import '../../../data/models/program_model.dart';
import '../../../data/models/university_model.dart';
import '../../../domain/entities/program_entity.dart';
import '../../../domain/entities/university_entity.dart';
import 'university_search_state.dart';

class UniversitySearchCubit extends Cubit<UniversitySearchState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<String> _availableDegrees = [];
  List<String> _availableMajors = [];

  String _query = '';
  String _intake = 'All';
  String _degree = 'All';
  String _major = 'All';
  bool _requiresIelts = false;
  bool _acceptsMoi = false;
  double _maxTuition = 0;
  String _language = 'All';
  String _location = 'All';

  UniversitySearchCubit() : super(UniversitySearchInitial());

  List<String> get availableDegrees => List.unmodifiable(_availableDegrees);
  List<String> get availableMajors => List.unmodifiable(_availableMajors);

  List<String> _lastLocations = [];

  List<String> get availableLocations => List.unmodifiable(_lastLocations);

  Future<void> refresh() async {
    emit(UniversitySearchLoading());
    _availableDegrees = [];
    _availableMajors = [];
    await _fetchDegreesAndMajors();
    await _fetchFilteredData();
  }

  void clearAllFilters() {
    _query = '';
    _intake = 'All';
    _degree = 'All';
    _major = 'All';
    _requiresIelts = false;
    _acceptsMoi = false;
    _maxTuition = 0;
    _language = 'All';
    _location = 'All';
    _fetchFilteredData();
  }

  Future<void> updateFilters({
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

    if (_availableDegrees.isEmpty || _availableMajors.isEmpty) {
      await _fetchDegreesAndMajors();
    }
    await _fetchFilteredData();
  }

  Future<void> _fetchDegreesAndMajors() async {
    try {
      final degreeResult = await _supabase
          .from('university_programs')
          .select('degree_type')
          .limit(1000)
          .timeout(const Duration(seconds: 10));
      _availableDegrees = degreeResult
          .map<String>((r) => r['degree_type'] as String? ?? '')
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final majorResult = await _supabase
          .from('university_programs')
          .select('major')
          .limit(1000)
          .timeout(const Duration(seconds: 10));
      _availableMajors = majorResult
          .map<String>((r) => r['major'] as String? ?? '')
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } catch (_) {
      _availableDegrees = ['Bachelor', 'Master', 'PhD'];
      _availableMajors = ['Computer Science', 'Medicine', 'Engineering'];
    }
  }

  Future<void> _fetchFilteredData() async {
    bool isInitialOrError = state is UniversitySearchInitial || state is UniversitySearchError;
    if (isInitialOrError) {
      emit(UniversitySearchLoading());
    }
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final Map<String, dynamic> profile = (await _supabase
          .from('profiles')
          .select('degree_level, has_ielts, ielts_score, has_toefl, toefl_score, has_moi, target_major, language_preference, gpa, max_gpa, academic_average, high_school_score, has_transcripts, has_bachelor_cert, has_sop, has_cv, has_german_cert_doc')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10))) ?? <String, dynamic>{};

      var query = _supabase
          .from('university_programs')
          .select('*, university:university_id(*)');

      if (_query.isNotEmpty) {
        query = query.ilike('university.name', '%$_query%');
      }
      if (_degree != 'All') {
        query = query.eq('degree_type', _degree);
      }
      if (_major != 'All') {
        query = query.ilike('major', '%$_major%');
      }
      if (_intake == 'Winter Semester') {
        query = query.or('intake_type.eq.Winter,intake_type.eq.Both');
      } else if (_intake == 'Summer Semester') {
        query = query.or('intake_type.eq.Summer,intake_type.eq.Both');
      }
      if (_language != 'All') {
        query = query.eq('instruction_language', _language);
      }
      if (_requiresIelts) {
        query = query.eq('requires_ielts', true);
      }
      if (_acceptsMoi) {
        query = query.eq('accepts_moi', true);
      }
      if (_maxTuition > 0) {
        query = query.lte('tuition_fee_per_year', _maxTuition);
      }

      final response = await query.limit(200).timeout(const Duration(seconds: 10));

      final Map<String, UniversityEntity> uniMap = {};
      for (final row in response) {
        final programData = Map<String, dynamic>.from(row as Map);
        final uniData = programData['university'] as Map<String, dynamic>?;
        if (uniData == null) continue;
        if (uniData['country'] != 'Germany') continue;

        final uniId = uniData['id'].toString();
        if (!uniMap.containsKey(uniId)) {
          uniMap[uniId] = UniversityModel.fromJson(uniData).toEntity();
        }

        final p = ProgramModel.fromJson(programData).toEntity();
        final score = MatchScoreCalculator.calculate(
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

        final updatedProgram = ProgramEntity(
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
          programUrl: p.programUrl,
        );

        final uni = uniMap[uniId]!;
        uniMap[uniId] = uni.copyWith(
          programs: [...uni.programs, updatedProgram],
        );
      }

      var universities = uniMap.values.toList();

      if (_location != 'All') {
        universities = universities.where((u) {
          final loc = u.location ?? '';
          return loc.toLowerCase().contains(_location.toLowerCase());
        }).toList();
      }

      for (int i = 0; i < universities.length; i++) {
        final u = universities[i];
        final maxScore = u.programs.isEmpty
            ? 0
            : u.programs.map((p) => p.matchScore).reduce(
                  (a, b) => a > b ? a : b,
                );
        universities[i] = u.copyWith(
          matchPercentage: maxScore,
          matchedProgramsCount: u.programs.where((p) => p.isRecommended).length,
        );
      }

      _lastLocations = universities
          .map((u) => u.location ?? '')
          .where((l) => l.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      emit(
        UniversitySearchLoaded(
          allResults: universities,
          filteredResults: universities,
          selectedIntake: _intake,
          selectedDegree: _degree,
          selectedMajor: _major,
          requiresIelts: _requiresIelts,
          acceptsMoi: _acceptsMoi,
          maxTuition: _maxTuition,
          selectedLanguage: _language,
          selectedLocation: _location,
          availableDegrees: _availableDegrees,
          availableMajors: _availableMajors,
        ),
      );
    } catch (e) {
      emit(UniversitySearchError(e.toString()));
    }
  }

  bool isProgramMatchingFilters(dynamic program) {
    final matchesIntake =
        _intake == 'All' ||
        _intake == 'Both Semesters' ||
        program.intakeType == 'Both' ||
        _intake.contains(program.intakeType);
    return matchesIntake && (program.tuitionFeePerYear <= _maxTuition);
  }
}
