import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/services_locator.dart';
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
    // 🎯 الحل هنا: توفير الـ ProfileCubit والـ LogoutCubit معاً في بداية الشاشة
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<ProfileCubit>()..getUserProfile()),
        BlocProvider(create: (context) => sl<LogoutCubit>()),
      ],
      child: BlocListener<LogoutCubit, LogoutState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged out successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // الراوتر سيقوم بالتحويل لصفحة اللوجن تلقائياً
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
          backgroundColor: const Color(0xFFF8FAFC),
          endDrawer: const SideNavigationBar(),
          body: SafeArea(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
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
                            _buildHeader(),
                            SizedBox(height: 24.h),
                            _buildProfileCard(state),
                            SizedBox(height: 32.h),
                            const Text(
                              'Account & Tools',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // 1. زر المستندات
                            ProfileToolItem(
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

                            // 2. زر الإعدادات
                            ProfileToolItem(
                              icon: Icons.settings_outlined,
                              iconColor: Colors.grey,
                              title: 'Account Settings',
                              subtitle: 'Update your Profile & Preferences',
                              onTap: () => context.push(
                                '/settings',
                                extra: context.read<ProfileCubit>(),
                              ),
                            ),

                            // 3. زر تسجيل الخروج
                            ProfileToolItem(
                              icon: Icons.logout,
                              iconColor: Colors.red,
                              title: 'Logout',
                              subtitle: 'Sign out of UniPath',
                              onTap: () => _showLogoutConfirmation(context),
                            ),
                          ],
                        ),
                      ));
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
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
            color: const Color(0xFF4F46E5).withOpacity(0.2),
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
            backgroundColor: Colors.white.withOpacity(0.2),
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
            '${state.user.targetMajor} • ${state.user.languagePreference} Track',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
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
          color: Colors.white.withOpacity(0.15),
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LogoutCubit>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
