import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/notification_service.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/match_score_card.dart';
import '../widgets/university_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🎯 وحدة التحكم في السكرول لاكتشاف النهاية
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🎯 وظيفة اكتشاف الوصول لنهاية الصفحة لطلب المزيد من البيانات
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HomeCubit>().loadMoreUniversities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await NotificationService.notifyUpcomingDeadline(
            'Test Program - Computer Science',
            DateTime.now().add(const Duration(days: 2)).toIso8601String(),
            2,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔔 Test notification sent! Check notification shade.'),
                backgroundColor: Color(0xFF4F46E5),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.notifications_active, color: Colors.white),
      ),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              );
            }

            if (state is HomeError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (state is HomeLoaded) {
              return RefreshIndicator(
                // 🎯 سحب من أعلى للتحديث (مثل My Applications)
                onRefresh: () async {
                  await context
                      .read<HomeCubit>()
                      .calculateAndFetchRecommendations(forceRefresh: true);
                },
                color: const Color(0xFF4F46E5),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, Mahmoud 👋",
                        style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      MatchScoreCard(score: state.matchScore),
                      SizedBox(height: 32.h),

                      Text(
                        "Recommended for you",
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // قائمة الجامعات
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.recommendations.length,
                        itemBuilder: (context, index) {
                          return UniversityCard(
                            university: state.recommendations[index],
                          );
                        },
                      ),

                      // 🎯 مؤشر تحميل في الأسفل عند جلب صفحة جديدة
                      if (state.isFetchingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),

                      if (state.hasReachedMax &&
                          state.recommendations.isNotEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              "You've seen all available programs!",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
