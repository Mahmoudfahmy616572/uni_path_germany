import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../auth/logout/cubit/logout_cubit.dart';
// import 'path_to_your_logout_cubit.dart';

class SideNavigationBar extends StatelessWidget {
  const SideNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF4F46E5)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              accountName: const Text(
                'Ahmed Hassan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('ahmed.hassan@example.com'),
            ),
            ListTile(
              leading: const Icon(
                Icons.manage_accounts_outlined,
                color: Colors.grey,
              ),
              title: const Text('Account Settings'),
              subtitle: const Text('Update email, password, username'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.translate_outlined, color: Colors.grey),
              title: const Text('Language & Region'),
              subtitle: const Text('App language, target cities'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined, color: Colors.grey),
              title: const Text('Dark Mode'),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.grey),
              title: const Text('Help & Support'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: Colors.grey,
              ),
              title: const Text('Privacy Policy'),
              onTap: () {},
            ),
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
                  Navigator.pop(context); // يقفل الـ Drawer
                  // بننادي الـ Cubit مباشرة من الـ context المحيط
                  context.read<LogoutCubit>().logout();
                },
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}
