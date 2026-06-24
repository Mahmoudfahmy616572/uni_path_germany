import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/widgets/curtain_drop.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _drawerWidth = 260.0;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyAdmin());
  }

  Future<void> _verifyAdmin() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final isAdmin = profile?['role'] == 'admin';
      if (!isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Access denied. Admin privileges required.'),
            backgroundColor: Colors.red,
          ));
          context.go('/home');
        }
        return;
      }
      if (mounted) setState(() => _checkingAuth = false);
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/admin/users')) return 1;
    if (location.startsWith('/admin/universities')) return 2;
    if (location.startsWith('/admin/programs')) return 3;
    if (location.startsWith('/admin/applications')) return 4;
    if (location.startsWith('/admin/documents')) return 5;
    if (location.startsWith('/admin/settings')) return 6;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexForLocation(location);

    final navItems = [
      _NavItem(Icons.dashboard_outlined, 'Overview', '/admin'),
      _NavItem(Icons.people_outline, 'Users', '/admin/users'),
      _NavItem(Icons.school_outlined, 'Universities', '/admin/universities'),
      _NavItem(Icons.menu_book_outlined, 'Programs', '/admin/programs'),
      _NavItem(Icons.assignment_outlined, 'Applications', '/admin/applications'),
      _NavItem(Icons.folder_outlined, 'Documents', '/admin/documents'),
      _NavItem(Icons.settings_outlined, 'Settings', '/admin/settings'),
    ];

    final sidebar = Container(
      width: _drawerWidth,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          CurtainDrop(
            index: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.shield_outlined, color: Colors.white, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UniPath', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                      Text('Admin', style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          SizedBox(height: 8.h),
          ...navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return CurtainDrop(
              index: i + 1,
              child: _SidebarTile(
                item: item,
                selected: selectedIndex == i,
                onTap: () {
                  if (selectedIndex != i) {
                    context.go(item.path);
                  }
                },
              ),
            );
          }),
          const Spacer(),
          CurtainDrop(
            index: 8,
            child: Container(
              padding: EdgeInsets.all(16.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(10.r),
                onTap: () => context.go('/profile'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white54, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text('My Profile', style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );

    if (_checkingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E293B),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            sidebar,
            const VerticalDivider(width: 1, color: Colors.black12),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(navItems[selectedIndex].label, style: TextStyle(color: Colors.white, fontSize: 16.sp)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white70),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      drawer: Drawer(child: sidebar),
      body: widget.child,
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem(this.icon, this.label, this.path);
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: selected ? Colors.white : Colors.white54, size: 20.sp),
                SizedBox(width: 12.w),
                Text(item.label, style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14.sp,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
