import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/university_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  // دالة عشان تحسب الـ Score وتجيب الجامعات المناسبة ليه
  void calculateAndFetchRecommendations(int userScore) async {
    emit(HomeLoading());

    try {
      // هنا بنعمل تأخير بسيط كأننا بنجيب الداتا من Supabase أو الـ API
      await Future.delayed(const Duration(seconds: 1));

      // دي داتا Mock هنفلترها بناءً على الـ Score بتاع اليوزر
      final List<UniversityModel> allUniversities = [
        UniversityModel(
          logoText: "TUM",
          name: "TU Munich",
          program: "MSc in Data Science",
          matchPercentage: 85,
        ),
        UniversityModel(
          logoText: "RWTH",
          name: "RWTH Aachen",
          program: "MSc in Software Eng",
          matchPercentage: 78,
        ),
        UniversityModel(
          logoText: "HU",
          name: "Humboldt Univ",
          program: "MSc in Comp Science",
          matchPercentage: 65,
        ),
        UniversityModel(
          logoText: "FU",
          name: "Freie Universität",
          program: "MSc in AI",
          matchPercentage: 55,
        ),
        UniversityModel(
          logoText: "TUD",
          name: "TU Darmstadt",
          program: "MSc in IT",
          matchPercentage: 45,
        ),
      ];

      // Logic الفلترة: هنجيب الجامعات اللي الـ match بتاعها قريب من سكور اليوزر (مثلاً فرق 15% فوق أو تحت)
      final List<UniversityModel> recommended = allUniversities.where((uni) {
        return uni.matchPercentage >= (userScore - 15) &&
            uni.matchPercentage <= (userScore + 15);
      }).toList();

      // بنبعت الـ State الجديد للشاشة
      emit(HomeLoaded(matchScore: userScore, recommendations: recommended));
    } catch (e) {
      emit(HomeError("Failed to fetch recommendations."));
    }
  }
}
