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

  static ScrollController? scrollController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🎯 وحدة التحكم في السكرول لاكتشاف النهاية
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    HomeScreen.scrollController = _scrollController;
    _scrollController.addListener(_onScroll);
    _checkProfileCompletionAndShowWelcome();
  }

  @override
  void dispose() {
    HomeScreen.scrollController = null;
    _scrollController.dispose();
    super.dispose();
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
              return ShimmerList(
                itemCount: 5,
                itemHeight: 140.h,
                borderRadius: 16,
                padding: EdgeInsets.all(24.r),
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
                        AppLocalizations.of(context).translate('noInternetConnection'),
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
                          AppLocalizations.of(context).translate('retry'),
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
                                  height: 20.h,
                                  width: 200.w,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              CurtainDrop(
                                index: 2,
                                child: ShimmerText(
                                  lines: 1,
                                  height: 16.h,
                                  width: 150.w,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ));
              }

              final footerCount = (state.isFetchingMore ? 1 : 0) +
                  (state.hasReachedMax && state.recommendations.isNotEmpty ? 1 : 0);
              final totalItems = 3 + state.recommendations.length + footerCount;

              return RefreshIndicator(
                onRefresh: () async {
                  await context
                      .read<HomeCubit>()
                      .calculateAndFetchRecommendations(forceRefresh: true);
                },
                color: const Color(0xFF4F46E5),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(24.r),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 24.h),
                        child: CurtainDrop(
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
                      );
                    }
                    if (index == 1) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 32.h),
                        child: CurtainDrop(
                          index: 1,
                          child: MatchScoreCard(
                            score: state.matchScore,
                            onAiTap: () => _showGenericAiTips(context, state.matchScore),
                          ),
                        ),
                      );
                    }
                    if (index == 2) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: CurtainDrop(
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
                      );
                    }

                    final uniIndex = index - 3;
                    if (uniIndex < state.recommendations.length) {
                      return CurtainDrop(
                        index: (uniIndex + 3).clamp(3, 10),
                        child: UniversityCard(
                          university: state.recommendations[uniIndex],
                        ),
                      );
                    }

                    if (state.isFetchingMore) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                AppLocalizations.of(context).translate('loadingMore'),
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(top: 20.h),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate('seenAllPrograms'),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  },
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
    final tips = _getTips(context);
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
                AppLocalizations.of(context).translate('visitSettingsToComplete'),
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

  List<_AiTip> _getTips(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    if (score >= 80) {
      return [
        _AiTip(
          icon: Icons.check_circle_outline,
          title: t('strongProfile'),
          description: t('strongProfileDesc'),
        ),
        _AiTip(
          icon: Icons.description_outlined,
          title: t('polishDocuments'),
          description: t('polishDocumentsDesc'),
        ),
        _AiTip(
          icon: Icons.notifications_outlined,
          title: t('trackDeadlines'),
          description: t('trackDeadlinesDesc'),
        ),
      ];
    }
    if (score >= 60) {
      return [
        _AiTip(
          icon: Icons.grade_outlined,
          title: t('boostGpa'),
          description: t('boostGpaDesc'),
        ),
        _AiTip(
          icon: Icons.translate_outlined,
          title: t('languageCert'),
          description: t('languageCertDesc'),
        ),
        _AiTip(
          icon: Icons.school_outlined,
          title: t('refineMajor'),
          description: t('refineMajorDesc'),
        ),
      ];
    }
    if (score >= 40) {
      return [
        _AiTip(
          icon: Icons.person_outline,
          title: t('completeProfile'),
          description: t('completeProfileDesc'),
        ),
        _AiTip(
          icon: Icons.translate_outlined,
          title: t('getLanguageCertified'),
          description: t('getLanguageCertifiedDesc'),
        ),
        _AiTip(
          icon: Icons.calendar_today_outlined,
          title: t('pickIntake'),
          description: t('pickIntakeDesc'),
        ),
      ];
    }
    return [
      _AiTip(
        icon: Icons.person_outline,
        title: t('profileNeeded'),
        description: t('profileNeededDesc'),
      ),
      _AiTip(
        icon: Icons.search_outlined,
        title: t('explorePrograms'),
        description: t('exploreProgramsDesc'),
      ),
      _AiTip(
        icon: Icons.settings_outlined,
        title: t('visitSettings'),
        description: t('visitSettingsDesc'),
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
