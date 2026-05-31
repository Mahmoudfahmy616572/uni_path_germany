import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/match_score_card.dart';
import '../widgets/university_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFFF7FAFC,
      ), // لون الخلفية الفاتح من تصميمك
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            // 1. حالة التحميل (Loading)
            if (state is HomeLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF5A67D),
                ), // تعديل كود اللون ليكون سليم
              );
            }

            // 2. حالة حدوث خطأ (Error)
            if (state is HomeError) {
              return Center(
                child: Text(
                  state.message,
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
                ),
              );
            }

            // 3. حالة نجاح جلب البيانات (Loaded)
            if (state is HomeLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الـ Header الترحيبي باسمك يا هندسة
                    Text(
                      "Hello, Mahmoud 👋",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // الداتا الدايناميك المحسوبة جاية من الـ State هنا!
                    MatchScoreCard(score: state.matchScore),
                    const SizedBox(height: 30),

                    // Quick Actions (الـ Row بتاع الزراير الأربعة)
                    // يمكنك استدعاء الـ Widget المخصص ليها هنا لو منقصلة
                    const SizedBox(height: 35),

                    Text(
                      "Recommended for you",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // الـ Loop الذكي بتاعك على اللستة الحقيقية اللي جاية من الكوبيت والـ Repository
                    // 🎯 الـ Loop بعد تنظيف الـ parameters المتداخلة
                    ...state.recommendations.map(
                      (uni) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16.0,
                        ), // مسافة بين الكروت
                        child: UniversityCard(
                          university:
                              uni, // 👈 باصي الـ object كامل ومحمل بكل الداتا الجديدة والنسبة المحسوبة
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // الحالة الافتراضية
            return const SizedBox.shrink();
          },
        ),
      ),
      // 6. الـ Bottom Navigation Bar بتاعك ضيفه هنا تحت الـ SafeArea لو حابب
    );
  }
}
