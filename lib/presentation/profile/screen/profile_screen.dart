import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../auth/logout/cubit/logout_cubit.dart';
import '../../auth/logout/cubit/logout_state.dart';
import '../widgets/profile_tool_item.dart';
import '../widgets/side_navigation_bar.dart';

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
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Title + Settings Icon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28.sp,
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
                SizedBox(height: 24.h),

                // 2. Blue Profile Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF4F46E5),
                      ], // درجات اللون الأزرق/البنفسجي للـ Card
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Icon
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 40.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Name
                      Text(
                        'Ahmed Hassan',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Subtitle
                      Text(
                        'Computer Science Student • Germany Applicant',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 24.h),
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
                SizedBox(height: 32.h),

                // 3. Section Title
                Text(
                  'Account & Tools',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.h),

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
      width: 95.w,
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
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
