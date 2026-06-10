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
import '../../presentation/onboarding/screens/OnboardingScreen.dart';
import '../../presentation/profile/cubit/profile_cubit.dart';
import '../../presentation/profile/cubit/profile_state.dart'; // 🎯 مهم جداً
import '../../presentation/profile/screen/profile_screen.dart';
import '../../presentation/profile/widgets/documents_screen.dart';
import '../../presentation/profile/widgets/setting_screen.dart';
import '../../presentation/saved/screen/saved_screen.dart';
import '../../presentation/search/screen/university_search_screen.dart';
import '../services/services_locator.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding',
  refreshListenable: GoRouterRefreshStream(sl<AuthService>().authStateChanges),
  redirect: (context, state) {
    final bool isLoggedIn =
        Supabase.instance.client.auth.currentSession != null;
    final String currentLocation = state.matchedLocation;

    if (!isLoggedIn &&
        currentLocation != '/login' &&
        currentLocation != '/register' &&
        currentLocation != '/onboarding') {
      return '/login';
    }
    if (isLoggedIn &&
        (currentLocation == '/login' ||
            currentLocation == '/register' ||
            currentLocation == '/onboarding')) {
      return '/home';
    }
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

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          selectedItemColor: const Color(0xFF4F46E5),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 3) sl<MyApplicationsCubit>().loadApplications();
            navigationShell.goBranch(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Home",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              label: "Saved",
            ),
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
              path: '/saved',
              builder: (context, state) => const SavedScreen(),
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
