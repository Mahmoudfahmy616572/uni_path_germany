import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/logout/cubit/logout_cubit.dart';
import '../../../auth/logout/cubit/logout_state.dart';
import '../../widgets/profile_tool_item.dart';
import '../../widgets/side_navigation_bar.dart';

// تأكد من مسار الـ Cubit والـ State الصحيح في مشروعك
// import 'package:germany_travel/presentation/profile/cubit/logout_cubit.dart';
// import 'package:germany_travel/presentation/profile/cubit/logout_state.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutCubit, LogoutState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // الـ Router هيحول تلقائياً لـ /login بفضل الـ refreshListenable
        } else if (state is LogoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        endDrawer: SideNavigationBar(), // لون الخلفية الفاتح المائل للرمادي
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Title + Settings Icon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        // هنا تقدر تفتح إعدادات أو تخليه يعمل الـ Logout مؤقتاً للتأكيد
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Blue Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF4F46E5),
                      ], // درجات اللون الأزرق/البنفسجي للـ Card
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      const Text(
                        'Ahmed Hassan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Subtitle
                      Text(
                        'Computer Science Student • Germany Applicant',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats Row (Saved, Applied, Match)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('12', 'Saved'),
                          _buildStatItem('4', 'Applied'),
                          _buildStatItem('72%', 'Match'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Section Title
                const Text(
                  'Account & Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Tools List Items
                ProfileToolItem(
                  icon: Icons.description_outlined,
                  iconColor: Colors.blue,
                  title: 'My Documents',
                  subtitle: 'CV, SOP & Certificates',
                ),
                ProfileToolItem(
                  icon: Icons.smart_toy_outlined,
                  iconColor: Colors.indigo,
                  title: 'AI Assistant',
                  subtitle: 'Get personalized help',
                ),
                ProfileToolItem(
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.redAccent,
                  title: 'Notifications',
                  subtitle: 'Deadlines & updates',
                ),

                // زرار تسجيل خروج إضافي صريح في اللستة للتسهيل عليك في التست
                ProfileToolItem(
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  onTap: () {
                    context.read<LogoutCubit>().logout();
                  },
                ),
              ],
            ),
          ),
        ),

        // 5. Bottom Navigation Bar (بنفس شكل الصورة)
      ),
    );
  }

  // الـ UI Widget الخاص بأرقام الإحصائيات داخل الكارد الأزرق
  Widget _buildStatItem(String value, String label) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // الـ UI Widget الخاص بالعناصر اللي تحت Account & Tools
  // Widget _buildToolItem({
  //   required IconData icon,
  //   required Color iconColor,
  //   required String title,
  //   required String subtitle,
  //   VoidCallback? onTap,
  // }) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.02),
  //           blurRadius: 6,
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: ListTile(
  //       leading: Container(
  //         padding: const EdgeInsets.all(8),
  //         decoration: BoxDecoration(
  //           color: iconColor.withOpacity(0.1),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Icon(icon, color: iconColor),
  //       ),
  //       title: Text(
  //         title,
  //         style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
  //       ),
  //       subtitle: Text(
  //         subtitle,
  //         style: const TextStyle(color: Colors.grey, fontSize: 12),
  //       ),
  //       trailing: const Icon(
  //         Icons.arrow_forward_ios,
  //         size: 14,
  //         color: Colors.grey,
  //       ),
  //       onTap: onTap,
  //     ),
  //   );
  // }

  // // الـ UI Widget الخاص بأيقونات الـ Bottom Navigation
  // Widget _buildNavItem(IconData icon, String label, bool isActive) {
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Icon(
  //         icon,
  //         color: isActive ? const Color(0xFF6366F1) : Colors.grey,
  //         size: 26,
  //       ),
  //       const SizedBox(height: 4),
  //       Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: 11,
  //           color: isActive ? const Color(0xFF6366F1) : Colors.grey,
  //           fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // نغلف الشاشة بالـ Listener عشان نسمع لحالة الـ Logout
  // Widget _buildSideNavigationBar(BuildContext context) {
  //   return Drawer(
  //     child: Container(
  //       color: Colors.white,
  //       child: Column(
  //         children: [
  //           // هيدر الـ Drawer (شكل بسيط وأنيق متناسق مع التطبيق)
  //           UserAccountsDrawerHeader(
  //             decoration: const BoxDecoration(
  //               color: Color(0xFF4F46E5), // نفس درجة اللون الأزرق الأساسي
  //             ),
  //             currentAccountPicture: CircleAvatar(
  //               backgroundColor: Colors.white.withOpacity(0.2),
  //               child: const Icon(
  //                 Icons.person,
  //                 size: 40,
  //                 color: Colors.white,
  //               ),
  //             ),
  //             accountName: const Text(
  //               'Ahmed Hassan',
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //             accountEmail: const Text('ahmed.hassan@example.com'),
  //           ),

  //           // 1. ترشيح: إعدادات الحساب
  //           ListTile(
  //             leading: const Icon(
  //               Icons.manage_accounts_outlined,
  //               color: Colors.grey,
  //             ),
  //             title: const Text('Account Settings'),
  //             subtitle: const Text('Update email, password, username'),
  //             onTap: () {
  //               // انقله لصفحة تعديل البيانات لو تحب مستقبلاً
  //             },
  //           ),

  //           // 2. ترشيح: اللغات والتفضيلات (بما إن الأبليكيشن يخص السفر لألمانيا)
  //           ListTile(
  //             leading: const Icon(
  //               Icons.translate_outlined,
  //               color: Colors.grey,
  //             ),
  //             title: const Text('Language & Region'),
  //             subtitle: const Text('App language, target cities'),
  //             onTap: () {},
  //           ),

  //           // 3. ترشيح: الوضع الليلي (Dark Mode)
  //           ListTile(
  //             leading: const Icon(
  //               Icons.dark_mode_outlined,
  //               color: Colors.grey,
  //             ),
  //             title: const Text('Dark Mode'),
  //             trailing: Switch(
  //               value: false, // اربطه بـ Theme Cubit لو عندك
  //               onChanged: (value) {},
  //             ),
  //           ),

  //           // 4. ترشيح: الدعم الفني والمساعدة
  //           ListTile(
  //             leading: const Icon(Icons.help_outline, color: Colors.grey),
  //             title: const Text('Help & Support'),
  //             onTap: () {},
  //           ),

  //           const Divider(), // خط فاصل
  //           // 5. ترشيح: شروط الاستخدام والخصوصية
  //           ListTile(
  //             leading: const Icon(
  //               Icons.privacy_tip_outlined,
  //               color: Colors.grey,
  //             ),
  //             title: const Text('Privacy Policy'),
  //             onTap: () {},
  //           ),

  //           const Spacer(), // يزق زرار اللوج اوت لآخر الشاشة تحت
  //           // زرار الـ Logout مربوط بالـ Cubit
  //           SafeArea(
  //             child: ListTile(
  //               leading: const Icon(Icons.logout, color: Colors.red),
  //               title: const Text(
  //                 'Logout',
  //                 style: TextStyle(
  //                   color: Colors.red,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               onTap: () {
  //                 Navigator.pop(context); // يقفل الـ Drawer الأول
  //                 context.read<LogoutCubit>().logout(); // ينادي اللوجيك
  //               },
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
