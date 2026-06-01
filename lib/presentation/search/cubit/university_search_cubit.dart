import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/university_model.dart';
import 'university_search_state.dart';

class UniversitySearchCubit extends Cubit<UniversitySearchState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<UniversityModel> _cachedUniversities = [];

  String _currentQuery = '';
  String _country = 'All';
  String _degree = 'All';
  String _major = 'All';
  bool _requiresIelts = false;
  bool _acceptsMoi = false;
  double _maxTuition = 20000.0;
  String _language = 'All';

  UniversitySearchCubit() : super(UniversitySearchInitial());

  void clearAllFilters() {
    _currentQuery = '';
    _country = 'All';
    _degree = 'All';
    _major = 'All';
    _requiresIelts = false;
    _acceptsMoi = false;
    _maxTuition = 20000.0;
    _language = 'All';
    updateFilters();
  }

  void updateFilters({
    String? query,
    String? country,
    String? degree,
    String? major,
    bool? requiresIelts,
    bool? acceptsMoi,
    double? maxTuition,
    String? language,
    bool forceRefresh = false,
  }) async {
    if (query != null) _currentQuery = query;
    if (country != null) _country = country;
    if (degree != null) _degree = degree;
    if (major != null) _major = major;
    if (requiresIelts != null) _requiresIelts = requiresIelts;
    if (acceptsMoi != null) _acceptsMoi = acceptsMoi;
    if (maxTuition != null) _maxTuition = maxTuition;
    if (language != null) _language = language;

    if (_cachedUniversities.isEmpty || forceRefresh) {
      emit(UniversitySearchLoading());
      try {
        final response = await _supabase.from('test_universities').select();
        _cachedUniversities = (response as List)
            .map((json) => UniversityModel.fromJson(json))
            .toList();
      } catch (e) {
        emit(UniversitySearchError(e.toString()));
        return;
      }
    }

    List<UniversityModel> filtered = _cachedUniversities.where((uni) {
      // 1. فلتر نص البحث (الاسم أو البرنامج)
      final matchesQuery =
          _currentQuery.isEmpty ||
          uni.name.toLowerCase().contains(_currentQuery.toLowerCase()) ||
          uni.program.toLowerCase().contains(_currentQuery.toLowerCase());

      // 2. فلتر الدولة (بما إنك هترسي على ألمانيا، السطر ده هيظبطها تماماً)
      final matchesCountry =
          _country == 'All' ||
          uni.country.toLowerCase() == _country.toLowerCase();

      // 3. فلتر الدرجة العلمية (Master / Bachelor,phD)
      final matchesDegree =
          _degree == 'All' ||
          uni.degreeType.toLowerCase() == _degree.toLowerCase();

      // 4. فلتر التخصص (Major)
      final matchesMajor =
          _major == 'All' ||
          uni.program.toLowerCase().contains(_major.toLowerCase());

      // 5. فلتر الآيلتس (IELTS)
      final matchesIelts = !_requiresIelts || uni.requiresIelts == true;

      // 6. فلتر الـ MOI الحقيقي بناءً على حقل الداتابيز الجديد
      final matchesMoi = !_acceptsMoi || uni.acceptsMoi == true;

      // 7. فلتر الرسوم الدراسية (Tuition Fees)
      final matchesTuition = (uni.tuitionFeePerYear ?? 0) <= _maxTuition;

      // 8. الفلتر الذكي والمحدد للغة التدريس (إنجليزي أو ألماني بالملي) 🔥
      bool matchesLanguage = true;
      if (_language != 'All') {
        // هنا بنقارن القيمة اللي جاية من السيرفر مباشرة (بعد تحويلها لـ lowercase عشان نتفادي أي اختلاف حروف)
        // لو الكولم لسه مش متهندل في الموديل، هنقراه مؤقتاً كدة من الـ description أو من الـ dynamic json لو بتمرره
        final uniLang = uni.instructionLanguage?.toLowerCase() ?? 'english';
        matchesLanguage = uniLang == _language.toLowerCase();
      }

      return matchesQuery &&
          matchesCountry &&
          matchesDegree &&
          matchesMajor &&
          matchesIelts &&
          matchesMoi &&
          matchesTuition &&
          matchesLanguage;
    }).toList();
    emit(
      UniversitySearchLoaded(
        allResults: _cachedUniversities,
        filteredResults: filtered,
        selectedCountry: _country,
        selectedDegree: _degree,
        selectedMajor: _major,
        requiresIelts: _requiresIelts,
        acceptsMoi: _acceptsMoi,
        maxTuition: _maxTuition,
        selectedLanguage: _language,
      ),
    );
  }
}
