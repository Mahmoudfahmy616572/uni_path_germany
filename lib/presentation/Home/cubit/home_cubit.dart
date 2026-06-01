import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/university_model.dart';
import '../../../domain/repositories/universities_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final UniversitiesRepository universitiesRepository;

  HomeCubit(this.universitiesRepository) : super(HomeInitial());

  void calculateAndFetchRecommendations({bool forceRefresh = false}) async {
    if (state is HomeLoaded && !forceRefresh) return;

    emit(HomeLoading());
    try {
      final List<UniversityModel> recommended = await universitiesRepository
          .fetchMatchedUniversities();

      int userTotalScore = recommended.isNotEmpty
          ? recommended.first.matchPercentage
          : 0;

      emit(
        HomeLoaded(matchScore: userTotalScore, recommendations: recommended),
      );
    } catch (e) {
      emit(HomeError(e.toString().replaceAll('Exception:', '').trim()));
    }
  }

  // 🔥 دالة التحديث المحلي الفوري لمنع الحاجه لـ هوت ريستارت
  void updateUniversityStatusLocally(String universityId, String newStatus) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;

      final updatedList = currentState.recommendations.map((uni) {
        if (uni.id == universityId) {
          // بناء نسخة جديدة بالحالة الجديدة بالملي
          return UniversityModel(
            id: uni.id,
            name: uni.name,
            program: uni.program,
            matchPercentage: uni.matchPercentage,
            logoText: uni.logoText,
            requiredGpa: uni.requiredGpa,
            requiresIelts: uni.requiresIelts,
            minIeltsScore: uni.minIeltsScore,
            country: uni.country,
            description: uni.description,
            curriculum: uni.curriculum,
            rankings: uni.rankings,
            logoUrl: uni.logoUrl,
            deadline: uni.deadline,
            applicationFee: uni.applicationFee,
            tuitionFeePerYear: uni.tuitionFeePerYear,
            status: newStatus, // 👈 تحديث الحالة هنا
            notes: uni.notes,
            hasTranscripts: uni.hasTranscripts,
            hasCv: uni.hasCv,
            hasSop: uni.hasSop,
            hasBachelorCert: uni.hasBachelorCert,
            acceptsMoi: uni.acceptsMoi,
            instructionLanguage: uni.instructionLanguage,
            degreeType: uni.degreeType,
          );
        }
        return uni;
      }).toList();

      emit(
        HomeLoaded(
          matchScore: updatedList.isNotEmpty
              ? updatedList.first.matchPercentage
              : 0,
          recommendations: updatedList,
        ),
      );
    }
  }
}
