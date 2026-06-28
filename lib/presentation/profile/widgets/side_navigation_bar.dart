import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../auth/logout/cubit/logout_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class SideNavigationBar extends StatelessWidget {
  Widget _settingsTile(BuildContext context, String label, IconData icon, int section) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        context.push('/settings?section=$section', extra: context.read<ProfileCubit>());
      },
    );
  }
  const SideNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    // ðŸŽ¯ Ø¨Ù†Ø³Ù…Ø¹ Ù„Ù„Ù€ ProfileCubit Ø§Ù„Ù„ÙŠ Ù…ÙˆØ¬ÙˆØ¯ ÙÙŠ Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø£Ø¨ (ProfileScreen)
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String name = AppLocalizations.of(context).translate('loading');
        String email = "...";

        if (state is ProfileLoaded) {
          name = state.user.name;
          email = state.user.email;
        }

        return Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF4F46E5)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _settingsTile(context, AppLocalizations.of(context).translate('accountSettings'), Icons.manage_accounts_outlined, 0),
                    _settingsTile(context, AppLocalizations.of(context).translate('academicProfile'), Icons.school_outlined, 1),
                    _settingsTile(context, AppLocalizations.of(context).translate('preferences'), Icons.translate_outlined, 2),
                    _settingsTile(context, AppLocalizations.of(context).translate('languageCertificate'), Icons.menu_book_outlined, 3),
                    _settingsTile(context, AppLocalizations.of(context).translate('notifications'), Icons.notifications_outlined, 4),
                    _settingsTile(context, AppLocalizations.of(context).translate('appSettings'), Icons.tune_outlined, 5),
                    _settingsTile(context, AppLocalizations.of(context).translate('legal'), Icons.privacy_tip_outlined, 6),
                    _settingsTile(context, AppLocalizations.of(context).translate('dangerZone'), Icons.warning_amber_outlined, 7),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(AppLocalizations.of(context).translate('emailTracking')),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/email-tracking');
                      },
                    ),
                    if (state is ProfileLoaded && state.user.role == 'admin')
                      ListTile(
                        leading: const Icon(Icons.shield_outlined, color: Color(0xFF6366F1)),
                        title: Text(AppLocalizations.of(context).translate('adminDashboard'), style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin');
                        },
                      ),
                    const Divider(),
                  ],
                ),
              ),
              SafeArea(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context).translate('logout'),
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
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('logout')),
        content: Text(AppLocalizations.of(context).translate('confirmLogout')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).translate('cancel'), style: TextStyle(color: const Color(0xFF64748B))),
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
