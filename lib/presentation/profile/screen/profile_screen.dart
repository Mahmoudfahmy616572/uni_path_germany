import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/utils/custom_snack_bar.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../domain/entities/university_entity.dart';
import '../../auth/logout/cubit/logout_cubit.dart';
import '../../auth/logout/cubit/logout_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_tool_item.dart';
import '../widgets/side_navigation_bar.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // ðŸŽ¯ Ø§Ù„Ø­Ù„ Ù‡Ù†Ø§: ØªÙˆÙÙŠØ± Ø§Ù„Ù€ ProfileCubit ÙˆØ§Ù„Ù€ LogoutCubit Ù…Ø¹Ø§Ù‹ ÙÙŠ Ø¨Ø¯Ø§ÙŠØ© Ø§Ù„Ø´Ø§Ø´Ø©
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<ProfileCubit>()..getUserProfile()),
        BlocProvider(create: (context) => sl<LogoutCubit>()),
      ],
      child: BlocListener<LogoutCubit, LogoutState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).translate('loggedOutSuccess')),
                backgroundColor: Colors.green,
              ),
            );
            // Ø§Ù„Ø±Ø§ÙˆØªØ± Ø³ÙŠÙ‚ÙˆÙ… Ø¨Ø§Ù„ØªØ­ÙˆÙŠÙ„ Ù„ØµÙØ­Ø© Ø§Ù„Ù„ÙˆØ¬Ù† ØªÙ„Ù‚Ø§Ø¦ÙŠØ§Ù‹
          } else if (state is LogoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          endDrawer: const SideNavigationBar(),
          body: SafeArea(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoading) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerCard(height: 40, width: 120, borderRadius: 8),
                        SizedBox(height: 24.h),
                        ShimmerCard(height: 200, borderRadius: 24),
                        SizedBox(height: 32.h),
                        ShimmerCard(height: 20, width: 160, borderRadius: 8),
                        SizedBox(height: 16.h),
                        ...List.generate(3, (i) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: ShimmerCard(height: 60, borderRadius: 16),
                        )),
                      ],
                    ),
                  );
                }

                if (state is ProfileLoaded) {
                  return RefreshIndicator(
                      onRefresh: () async {
                        context.read<ProfileCubit>().getUserProfile();
                      },
                      color: const Color(0xFF4F46E5),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CurtainDrop(
                              index: 0,
                              child: _buildHeader(context),
                            ),
                            SizedBox(height: 24.h),
                            CurtainDrop(
                              index: 1,
                              child: _buildProfileCard(state),
                            ),
                            SizedBox(height: 32.h),
                            CurtainDrop(
                              index: 2,
                              child: Text(
                                'Account & Tools',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            CurtainDrop(
                              index: 3,
                              child: ProfileToolItem(
                                icon: Icons.description_outlined,
                                iconColor: Colors.blue,
                                title: 'My Documents',
                                subtitle: 'CV, SOP & Certificates',
                                onTap: () {
                                  final userFiles = UniversityEntity(
                                    id: 'global',
                                    name: 'Vault',
                                    matchPercentage: 0,
                                    logoText: 'V',
                                    country: 'Germany',
                                    programs: [],
                                    hasTranscripts: state.user.gpa,
                                    hasCv: state.user.budgetRange,
                                    hasSop: state.user.languagePreference,
                                    hasBachelorCert: state.user.intake,
                                  );
                                  context.push('/documents', extra: userFiles);
                                },
                              ),
                            ),

                            CurtainDrop(
                              index: 4,
                              child: ProfileToolItem(
                                icon: Icons.email_outlined,
                                iconColor: const Color(0xFF6366F1),
                                title: 'Email Tracking',
                                subtitle: 'Auto-detect application status from emails',
                                onTap: () => context.push('/email-tracking'),
                              ),
                            ),
                            CurtainDrop(
                              index: 5,
                              child: ProfileToolItem(
                                icon: Icons.settings_outlined,
                                iconColor: Colors.grey,
                                title: AppLocalizations.of(context).translate('accountSettings'),
                                subtitle: 'Update your Profile & Preferences',
                                onTap: () async {
                                  final saved = await context.push<bool>(
                                    '/settings',
                                    extra: context.read<ProfileCubit>(),
                                  );
                                  if (saved == true && context.mounted) {
                                    CustomSnackBar.show(
                                      context,
                                      message: AppLocalizations.of(context).translate('settingsSaved'),
                                    );
                                  }
                                },
                              ),
                            ),

                            if (state.user.role == 'admin')
                              CurtainDrop(
                                index: 6,
                                child: ProfileToolItem(
                                  icon: Icons.shield_outlined,
                                  iconColor: const Color(0xFF6366F1),
                                  title: 'Admin Dashboard',
                                  subtitle: 'Manage users, universities & more',
                                  onTap: () => context.push('/admin'),
                                ),
                              ),
                            CurtainDrop(
                              index: 7,
                              child: ProfileToolItem(
                                icon: Icons.logout,
                                iconColor: Colors.red,
                                title: AppLocalizations.of(context).translate('logout'),
                                subtitle: 'Sign out of UniPath',
                                onTap: () => _showLogoutConfirmation(context),
                              ),
                            ),
                          ],
                        ),
                      ));
                }
                if (state is ProfileError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64.sp, color: Colors.grey[400]),
                          SizedBox(height: 16.h),
                          Text(
                            'Could not load profile',
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Please make sure you are logged in.',
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: () => context.read<ProfileCubit>().getUserProfile(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context).translate('profile'),
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: context.isDark ? AppColors.textMain : const Color(0xFF0F172A),
          ),
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B)),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    );
  }

  Widget _buildProfileCard(ProfileLoaded state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          SizedBox(height: 16.h),
          Text(
            state.user.name,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '${state.user.targetMajor} | ${state.user.languagePreference} Track',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              _buildStatItem(state.savedCount.toString(), 'Saved'),
              SizedBox(width: 8.w),
              _buildStatItem(state.appliedCount.toString(), 'Applied'),
              SizedBox(width: 8.w),
              _buildStatItem('${state.averageMatch}%', 'Match'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('logout')),
        content: const Text('Are you sure you want to log out?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).translate('cancel'),
                style: TextStyle(color: context.isDark ? AppColors.textMuted : const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LogoutCubit>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).translate('logout')),
          ),
        ],
      ),
    );
  }
}
