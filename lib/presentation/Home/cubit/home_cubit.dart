import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/university_entity.dart';
import '../../../domain/repositories/universities_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final UniversitiesRepository universitiesRepository;

  HomeCubit(this.universitiesRepository) : super(HomeInitial());

  List<UniversityEntity> _allRecommendations = [];
  final int _pageSize = 10;
  int _displayCount = 0;

  /// جلب جميع التوصيات من API، ثم عرض أول 10
  Future<void> calculateAndFetchRecommendations({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && state is HomeLoaded) return;

    emit(HomeLoading());

    try {
      _allRecommendations = await universitiesRepository
          .fetchMatchedUniversities(page: 1, limit: 999);

      _displayCount = _pageSize.clamp(0, _allRecommendations.length);
      int userTotalScore = _calculateTopMatch(_allRecommendations);

      emit(
        HomeLoaded(
          matchScore: userTotalScore,
          recommendations: _allRecommendations.take(_displayCount).toList(),
          hasReachedMax: _displayCount >= _allRecommendations.length,
        ),
      );
    } catch (e) {
      emit(HomeError("Failed to load recommendations. Please try again."));
    }
  }

  /// عرض الـ 10 التالية من القائمة الكاملة المخزنة في الذاكرة
  Future<void> loadMoreUniversities() async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;
    if (current.isFetchingMore || current.hasReachedMax) return;

    emit(current.copyWith(isFetchingMore: true));

    _displayCount =
        (_displayCount + _pageSize).clamp(0, _allRecommendations.length);

    emit(
      current.copyWith(
        recommendations: _allRecommendations.take(_displayCount).toList(),
        isFetchingMore: false,
        hasReachedMax: _displayCount >= _allRecommendations.length,
      ),
    );
  }

  int _calculateTopMatch(List<UniversityEntity> list) {
    if (list.isEmpty) return 0;
    return list.map((u) => u.matchPercentage).reduce((a, b) => a > b ? a : b);
  }

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
