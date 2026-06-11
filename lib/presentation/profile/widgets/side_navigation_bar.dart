import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../auth/logout/cubit/logout_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class SideNavigationBar extends StatelessWidget {
  const SideNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎯 بنسمع للـ ProfileCubit اللي موجود في الشاشة الأب (ProfileScreen)
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String name = "Loading...";
        String email = "...";

        if (state is ProfileLoaded) {
          name = state.user.name;
          email = state.user.email;
        }

        return Drawer(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF4F46E5)),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  accountName: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(email),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Account Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings', extra: context.read<ProfileCubit>());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.translate_outlined),
                  title: const Text('Language & Intake'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings', extra: context.read<ProfileCubit>());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings', extra: context.read<ProfileCubit>());
                  },
                ),
                const Divider(),
                const Spacer(),
                SafeArea(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation(context);
                    },
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: const Color(0xFF64748B))),
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
