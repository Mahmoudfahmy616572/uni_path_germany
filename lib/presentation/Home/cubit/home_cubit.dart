import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/university_entity.dart';
import '../../../domain/repositories/universities_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final UniversitiesRepository universitiesRepository;

  // متغيرات لتتبع حالة الصفحات
  int _currentPage = 1;
  final int _pageSize = 10; // عدد العناصر في كل مرة

  HomeCubit(this.universitiesRepository) : super(HomeInitial());

  // 1️⃣ جلب التوصيات (البداية أو التحديث الشامل)
  Future<void> calculateAndFetchRecommendations({
    bool forceRefresh = false,
  }) async {
    // إذا طلبنا تحديث شامل، نصفر العدادات
    if (forceRefresh) {
      _currentPage = 1;
    } else if (state is HomeLoaded) {
      return; // البيانات موجودة بالفعل ولا نحتاج لتحديث
    }

    emit(HomeLoading());

    try {
      final List<UniversityEntity> recommended = await universitiesRepository
          .fetchMatchedUniversities(page: _currentPage, limit: _pageSize);

      // حساب أعلى نسبة مطابقة لعرضها في الكارت العلوي
      int userTotalScore = _calculateTopMatch(recommended);

      emit(
        HomeLoaded(
          matchScore: userTotalScore,
          recommendations: recommended,
          hasReachedMax:
              recommended.length <
              _pageSize, // لو العدد أقل من الصفحة يبقى خلصنا
        ),
      );
    } catch (e) {
      emit(HomeError("Failed to load recommendations. Please try again."));
    }
  }

  // 2️⃣ 🎯 وظيفة الـ Pagination (تحميل المزيد عند السكرول)
  Future<void> loadMoreUniversities() async {
    final currentState = state;

    // شروط التوقف: لو بنحمل حالياً، أو وصلنا للنهاية، أو الحالة مش Loaded
    if (currentState is! HomeLoaded ||
        currentState.isFetchingMore ||
        currentState.hasReachedMax) {
      return;
    }

    // تفعيل مؤشر التحميل في أسفل القائمة
    emit(currentState.copyWith(isFetchingMore: true));

    try {
      _currentPage++;
      final List<UniversityEntity> moreUnis = await universitiesRepository
          .fetchMatchedUniversities(page: _currentPage, limit: _pageSize);

      // دمج القائمة القديمة مع الجديدة
      final List<UniversityEntity> updatedList = List.from(
        currentState.recommendations,
      )..addAll(moreUnis);

      // تحديث الماتش سكور لو ظهرت جامعة بنسبة أعلى في الصفحة الجديدة
      int updatedTopScore = _calculateTopMatch(updatedList);

      emit(
        currentState.copyWith(
          recommendations: updatedList,
          matchScore: updatedTopScore,
          isFetchingMore: false,
          hasReachedMax: moreUnis.length < _pageSize,
        ),
      );
    } catch (e) {
      // في حالة الخطأ، نوقف التحميل فقط ونحتفظ بالبيانات القديمة
      emit(currentState.copyWith(isFetchingMore: false));
    }
  }

  // دالة مساعدة لحساب أعلى سكور
  int _calculateTopMatch(List<UniversityEntity> list) {
    if (list.isEmpty) return 0;
    return list.map((u) => u.matchPercentage).reduce((a, b) => a > b ? a : b);
  }

  // تحديث حالة جامعة معينة محلياً (لو تم الحفظ/الحذف من الخارج)
  void updateUniversityStatusLocally(String universityId, String newStatus) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final updatedList = currentState.recommendations.map((uni) {
        return uni.id == universityId ? uni.copyWith(status: newStatus) : uni;
      }).toList();
      emit(currentState.copyWith(recommendations: updatedList));
    }
  }
}
