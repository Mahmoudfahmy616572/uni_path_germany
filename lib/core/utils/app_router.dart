import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/services/auth/go_router_refresh_stream.dart';
import '../../domain/entities/university_entity.dart';
import '../../presentation/Home/screen/home_screen.dart';
import '../../presentation/MyApplications/cubit/my_applications_cubits.dart';
import '../../presentation/MyApplications/screens/my_applications_screen.dart';
import '../../presentation/UniversityDetails/screens/university_details_screen.dart';
import '../../presentation/auth/login/cubit/login_cubit.dart';
import '../../presentation/auth/login/screen/login_screen.dart';
import '../../presentation/auth/register/cubit/register_cubit.dart';
import '../../presentation/auth/register/screen/register_screen.dart';
import '../../presentation/onboarding/cubit/onboarding_cubit.dart';
import '../../presentation/onboarding/screens/onboarding_screen.dart';
import '../../presentation/profile/cubit/profile_cubit.dart';
import '../../presentation/profile/cubit/profile_state.dart';
import '../../presentation/profile/screen/profile_screen.dart';
import '../../presentation/profile/widgets/documents_screen.dart';
import '../../presentation/profile/widgets/setting_screen.dart';
import '../../presentation/admin/shell/admin_shell.dart';
import '../../presentation/admin/overview/admin_overview_screen.dart';
import '../../presentation/admin/users/admin_users_screen.dart';
import '../../presentation/admin/universities/admin_universities_screen.dart';
import '../../presentation/admin/programs/admin_programs_screen.dart';
import '../../presentation/admin/applications/admin_applications_screen.dart';
import '../../presentation/admin/documents/admin_documents_screen.dart';
import '../../presentation/admin/settings/admin_settings_screen.dart';
import '../../presentation/search/screen/university_search_screen.dart';
import '../services/services_locator.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding',
  refreshListenable: GoRouterRefreshStream(sl<AuthService>().authStateChanges),
  redirect: (context, state) {
    // Synchronous check for redirect
    final session = Supabase.instance.client.auth.currentSession;
    final bool isLoggedIn = session != null;
    final String currentLocation = state.matchedLocation;

    print('🔀 ROUTER REDIRECT: location=$currentLocation, isLoggedIn=$isLoggedIn');

    if (!isLoggedIn &&
        currentLocation != '/login' &&
        currentLocation != '/register' &&
        currentLocation != '/onboarding') {
      print('🔀 REDIRECT -> /login');
      return '/login';
    }
    if (isLoggedIn &&
        (currentLocation == '/login' ||
            currentLocation == '/register' ||
            currentLocation == '/onboarding')) {
      // For profile completeness, let the screen handle it (HomeScreen checks)
      print('🔀 REDIRECT -> /home');
      return '/home';
    }
    // REMOVED: Admin guard moved to AdminShell (was too early here — race with profile load)
    print('🔀 NO REDIRECT');
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => BlocProvider(
        create: (context) => OnboardingCubit(),
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<LoginCubit>(),
        child: LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<RegisterCubit>(),
        child: RegisterScreen(
          profileData: state.extra as Map<String, dynamic>?,
        ),
      ),
    ),

    // 🎯 إصلاح مسار شاشة الإعدادات
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        final profileCubit = state.extra as ProfileCubit;
        final currentState = profileCubit.state;

        // التحقق من نوع الحالة قبل الوصول للـ user
        if (currentState is ProfileLoaded) {
          return BlocProvider.value(
            value: profileCubit,
            child: SettingsScreen(user: currentState.user),
          );
        }

        // حالة احتياطية لو البيانات مش موجودة (نادراً ما تحدث)
        return const Scaffold(
          body: Center(child: Text("Error: Profile data not available")),
        );
      },
    ),

    GoRoute(
      path: '/documents',
      builder: (context, state) =>
          DocumentsScreen(userFiles: state.extra as UniversityEntity),
    ),

    GoRoute(
      path: '/university_details',
      builder: (context, state) =>
          UniversityDetailsScreen(university: state.extra as UniversityEntity),
    ),

    // ── Admin Dashboard Routes ──
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminOverviewScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: '/admin/universities',
          builder: (context, state) => const AdminUniversitiesScreen(),
        ),
        GoRoute(
          path: '/admin/programs',
          builder: (context, state) => const AdminProgramsScreen(),
        ),
        GoRoute(
          path: '/admin/applications',
          builder: (context, state) => const AdminApplicationsScreen(),
        ),
        GoRoute(
          path: '/admin/documents',
          builder: (context, state) => const AdminDocumentsScreen(),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) => const AdminSettingsScreen(),
        ),
      ],
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          selectedItemColor: const Color(0xFF4F46E5),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 2) sl<MyApplicationsCubit>().loadApplications();
            navigationShell.goBranch(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Home",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              label: "Applications",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profile",
            ),
          ],
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const UniversitySearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/applications',
              builder: (context, state) => BlocProvider.value(
                value: sl<MyApplicationsCubit>(),
                child: const MyApplicationsScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
