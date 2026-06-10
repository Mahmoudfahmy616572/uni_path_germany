import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/university_model.dart';
import '../../../domain/entities/university_entity.dart';
import 'university_search_state.dart';

class UniversitySearchCubit extends Cubit<UniversitySearchState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<UniversityEntity> _cachedUniversities = [];

  String _query = '';
  String _intake = 'All'; // تم استبدال الدولة بالفصل الدراسي
  String _degree = 'All';
  String _major = 'All';
  bool _requiresIelts = false;
  bool _acceptsMoi = false;
  double _maxTuition = 20000.0;
  String _language = 'All';

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
  }) async {
    if (query != null) _query = query;
    if (intake != null) _intake = intake;
    if (degree != null) _degree = degree;
    if (major != null) _major = major;
    if (requiresIelts != null) _requiresIelts = requiresIelts;
    if (acceptsMoi != null) _acceptsMoi = acceptsMoi;
    if (maxTuition != null) _maxTuition = maxTuition;
    if (language != null) _language = language;

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

      // جلب الجامعات الموجودة في "ألمانيا" فقط
      final response = await _supabase
          .from('universities')
          .select('*, university_programs(*)')
          .eq('country', 'Germany');

      _cachedUniversities = (response as List).map((json) {
        return UniversityModel.fromJson(
          Map<String, dynamic>.from(json),
        ).toEntity();
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
            final matchesDegree = _degree == 'All' || p.degreeType == _degree;
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

          if (matchedPrograms.isNotEmpty &&
              (_query.isEmpty ||
                  uni.name.toLowerCase().contains(_query.toLowerCase()))) {
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
        selectedCountry: 'Germany',
        selectedDegree: _degree,
        selectedMajor: _major,
        requiresIelts: _requiresIelts,
        acceptsMoi: _acceptsMoi,
        maxTuition: _maxTuition,
        selectedLanguage: _language,
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
}
