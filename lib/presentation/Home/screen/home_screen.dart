import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/utils/custom_snack_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
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
    _checkProfileCompletionAndShowWelcome();
  }

  Future<void> _checkProfileCompletionAndShowWelcome() async {
    final authService = sl<AuthService>();
    final profileComplete = await authService.isProfileComplete();
    if (!profileComplete && mounted) {
      context.go('/onboarding');
      return;
    }

    // Check if we just registered or logged in
    final prefs = await SharedPreferences.getInstance();
    final justRegistered = prefs.getBool('just_registered') ?? false;
    final justLoggedIn = prefs.getBool('just_logged_in') ?? false;

    if (justRegistered) {
      await prefs.setBool('just_registered', false);
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Account created successfully! Welcome to UniPath! 🎉',
          isError: false,
        );
      }
    } else if (justLoggedIn) {
      await prefs.setBool('just_logged_in', false);
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Welcome back! Successfully logged in. 👋',
          isError: false,
        );
      }
    }
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
                content: Text(
                    '🔔 Test notification sent! Check notification shade.'),
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
              return const ShimmerList(
                itemCount: 5,
                itemHeight: 140,
                borderRadius: 16,
                padding: EdgeInsets.all(24),
              );
            }

            if (state is HomeError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 64.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No internet connection',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.message,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () => context
                          .read<HomeCubit>()
                          .calculateAndFetchRecommendations(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'Try Again',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is HomeLoaded) {
              if (state.recommendations.isEmpty) {
                return RefreshIndicator(
                    onRefresh: () async {
                      await context
                          .read<HomeCubit>()
                          .calculateAndFetchRecommendations(forceRefresh: true);
                    },
                    color: const Color(0xFF4F46E5),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80.sp,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16.h),
                              ShimmerText(
                                lines: 2,
                                height: 20,
                                width: 200.w,
                              ),
                              SizedBox(height: 8.h),
                              ShimmerText(
                                lines: 1,
                                height: 16,
                                width: 150.w,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ));
              }

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
                        "Hello, Mahmoud",
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
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Loading more...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
