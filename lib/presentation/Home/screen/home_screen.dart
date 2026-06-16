import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/utils/custom_snack_bar.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../presentation/profile/cubit/profile_cubit.dart';
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
          message: AppLocalizations.of(context).translate('welcomeAccountCreated'),
          isError: false,
        );
      }
    } else if (justLoggedIn) {
      await prefs.setBool('just_logged_in', false);
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: AppLocalizations.of(context).translate('welcomeBackLogin'),
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

  void _showGenericAiTips(BuildContext context, int score) {
    final cubit = sl<ProfileCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _GenericAiTipsSheet(
        score: score,
        profileCubit: cubit,
        sheetContext: sheetContext,
        parentContext: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? AppColors.darkSurface : const Color(0xFFF7FAFC),
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
                    CurtainDrop(
                      index: 0,
                      child: Icon(
                        Icons.wifi_off,
                        size: 64.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    CurtainDrop(
                      index: 1,
                      child: Text(
                        'No internet connection',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    CurtainDrop(
                      index: 2,
                      child: Text(
                        state.message,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    CurtainDrop(
                      index: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => context
                            .read<HomeCubit>()
                            .calculateAndFetchRecommendations(
                                forceRefresh: true),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          'Try Again',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                              CurtainDrop(
                                index: 0,
                                child: Icon(
                                  Icons.search_off,
                                  size: 80.sp,
                                  color: Colors.grey[300],
                                ),
                              ),
                              SizedBox(height: 16.h),
                              CurtainDrop(
                                index: 1,
                                child: ShimmerText(
                                  lines: 2,
                                  height: 20,
                                  width: 200.w,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              CurtainDrop(
                                index: 2,
                                child: ShimmerText(
                                  lines: 1,
                                  height: 16,
                                  width: 150.w,
                                ),
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
                      CurtainDrop(
                        index: 0,
                        child: Text(
                          "${AppLocalizations.of(context).translate('matchScore')}, Mahmoud",
                          style: GoogleFonts.poppins(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: context.isDark ? AppColors.textMain : const Color(0xFF1A202C),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      CurtainDrop(
                        index: 1,
                        child: MatchScoreCard(
                          score: state.matchScore,
                          onAiTap: () => _showGenericAiTips(context, state.matchScore),
                        ),
                      ),
                      SizedBox(height: 32.h),

                      CurtainDrop(
                        index: 2,
                        child: Text(
                          AppLocalizations.of(context).translate('recommendedForYou'),
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: context.isDark ? AppColors.textMain : const Color(0xFF1A202C),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // قائمة الجامعات
                      CurtainDrop(
                        index: 3,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.recommendations.length,
                          itemBuilder: (context, index) {
                            return UniversityCard(
                              university: state.recommendations[index],
                            );
                          },
                        ),
                      ),

                      // 🎯 مؤشر تحميل في الأسفل عند جلب صفحة جديدة
                      if (state.isFetchingMore)
                        CurtainDrop(
                          index: 4,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20.sp,
                                    height: 20.sp,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
                        ),

                      if (state.hasReachedMax &&
                          state.recommendations.isNotEmpty)
                        const CurtainDrop(
                          index: 5,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                "You've seen all available programs!",
                                style: TextStyle(color: Colors.grey),
                              ),
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

class _GenericAiTipsSheet extends StatelessWidget {
  final int score;
  final ProfileCubit profileCubit;
  final BuildContext sheetContext;
  final BuildContext parentContext;

  const _GenericAiTipsSheet({
    required this.score,
    required this.profileCubit,
    required this.sheetContext,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final tips = _getTips();
    return Container(
      padding: EdgeInsets.only(top: 12.h),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: const Color(0xFF8B5CF6), size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  AppLocalizations.of(context).translate('aiTips'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: tips.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: context.isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: context.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(tip.icon, size: 18.sp, color: const Color(0xFF7C3AED)),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              tip.title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: context.isDark ? AppColors.textMain : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        tip.description,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8.h),
            Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                parentContext.push('/settings', extra: profileCubit);
              },
              icon: Icon(Icons.settings, size: 16.sp, color: const Color(0xFF8B5CF6)),
              label: Text(
                'Visit Settings to Complete Your Profile',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  List<_AiTip> _getTips() {
    if (score >= 80) {
      return [
        _AiTip(
          icon: Icons.check_circle_outline,
          title: 'Strong Profile',
          description: 'Your profile is a great match! Focus on submitting strong documents (CV, SOP, transcripts) for each application.',
        ),
        _AiTip(
          icon: Icons.description_outlined,
          title: 'Polish Your Documents',
          description: 'Use the AI Document Generator on each program page to create tailored CVs and motivation letters that highlight your strengths.',
        ),
        _AiTip(
          icon: Icons.notifications_outlined,
          title: 'Track Deadlines',
          description: 'Enable deadline reminders in Settings to never miss an application window.',
        ),
      ];
    }
    if (score >= 60) {
      return [
        _AiTip(
          icon: Icons.grade_outlined,
          title: 'Boost Your GPA Score',
          description: 'Consider retaking courses or highlighting relevant project experience in your SOP to compensate.',
        ),
        _AiTip(
          icon: Icons.translate_outlined,
          title: 'Language Certificate',
          description: 'Improving your IELTS score or getting an MOI certificate can add significant points to your match score.',
        ),
        _AiTip(
          icon: Icons.school_outlined,
          title: 'Refine Your Major',
          description: 'Visit Settings to ensure your target major is as specific as possible for better program matching.',
        ),
      ];
    }
    if (score >= 40) {
      return [
        _AiTip(
          icon: Icons.person_outline,
          title: 'Complete Your Profile',
          description: 'Your profile is incomplete. Adding your GPA, IELTS score, and target major will dramatically improve matching.',
        ),
        _AiTip(
          icon: Icons.translate_outlined,
          title: 'Get Language Certified',
          description: 'Most programs require IELTS (6.0+) or MOI. Adding either unlocks 10-15 points in the match score.',
        ),
        _AiTip(
          icon: Icons.calendar_today_outlined,
          title: 'Pick an Intake',
          description: 'Setting your target intake helps match with programs that align with your timeline.',
        ),
      ];
    }
    return [
      _AiTip(
        icon: Icons.person_outline,
        title: 'Profile Needed',
        description: 'Set up your academic profile in Settings — GPA, major, degree level, and language preferences.',
      ),
      _AiTip(
        icon: Icons.search_outlined,
        title: 'Explore Programs',
        description: 'Use the Search tab to find programs. Save interesting ones to see your match score.',
      ),
      _AiTip(
        icon: Icons.settings_outlined,
        title: 'Visit Settings',
        description: 'Complete all profile fields to unlock personalized AI suggestions for each program.',
      ),
    ];
  }
}

class _AiTip {
  final IconData icon;
  final String title;
  final String description;
  const _AiTip({required this.icon, required this.title, required this.description});
}
