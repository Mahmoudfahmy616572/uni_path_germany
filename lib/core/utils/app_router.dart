import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/services/auth/go_router_refresh_stream.dart';
import '../../data/models/university_model.dart';
import '../../domain/entities/university_entity.dart';
import '../../presentation/Home/cubit/home_cubit.dart';
import '../../presentation/Home/screen/home_screen.dart';
import '../../presentation/MyApplications/cubit/my_applications_cubits.dart';
import '../../presentation/MyApplications/screens/my_applications_screen.dart';
import '../../presentation/UniversityDetails/screens/university_details_screen.dart';
import '../../presentation/auth/login/cubit/login_cubit.dart';
import '../../presentation/auth/login/screen/login_screen.dart';
import '../../presentation/auth/logout/cubit/logout_cubit.dart';
import '../../presentation/auth/register/cubit/register_cubit.dart';
import '../../presentation/auth/register/screen/register_screen.dart';
import '../../presentation/onboarding/cubit/onboarding_cubit.dart';
import '../../presentation/onboarding/screens/OnboardingScreen.dart';
import '../../presentation/profile/screen/profile_screen.dart';
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
    final bool isGoingToAuth =
        currentLocation == '/login' || currentLocation == '/register';
    final bool isGoingToOnboarding = currentLocation == '/onboarding';

    if (!isLoggedIn) {
      if (!isGoingToAuth && !isGoingToOnboarding && currentLocation != '/') {
        return '/login';
      }
      return null;
    }
    if (isLoggedIn &&
        (isGoingToAuth || isGoingToOnboarding || currentLocation == '/')) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5A67D8)),
        ),
      ),
    ),
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
      builder: (context, state) {
        final profileData = state.extra as Map<String, dynamic>?;
        return BlocProvider(
          create: (context) => sl<RegisterCubit>(),
          child: RegisterScreen(profileData: profileData),
        );
      },
    ),
    GoRoute(
      path: '/university_details',
      builder: (context, state) {
        final extraData = state.extra;
        final UniversityModel university;
        if (extraData is UniversityModel) {
          university = extraData;
        } else if (extraData is UniversityEntity) {
          university = UniversityModel(
            id: extraData.id,
            name: extraData.name,
            program: extraData.program,
            country: extraData.country,
            matchPercentage: extraData.matchPercentage,
            logoText: extraData.logoText,
            requiresIelts: extraData.requiresIelts,
            requiredGpa: extraData.requiredGpa,
            minIeltsScore: extraData.minIeltsScore,
            acceptsMoi: extraData.acceptsMoi,
            instructionLanguage: extraData.instructionLanguage,
            degreeType: extraData.degreeType,
          );
        } else if (extraData is Map<String, dynamic>) {
          university = UniversityModel.fromJson(extraData);
        } else {
          throw Exception('Unexpected data type');
        }
        return UniversityDetailsScreen(university: university);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: navigationShell.currentIndex,
            selectedItemColor: const Color(0xFF5A67D8),
            unselectedItemColor: Colors.grey.shade400,
            onTap: (index) {
              // 🎯 التعديل: إجبار التحديث عند الضغط على تابة الـ Applications (Index 3)
              if (index == 3) {
                sl<MyApplicationsCubit>().loadApplications();
              }
              navigationShell.goBranch(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: "Search",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_border),
                label: "Saved",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.file_copy_outlined),
                label: "Applications",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: "Profile",
              ),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => BlocProvider(
                create: (context) =>
                    sl<HomeCubit>()..calculateAndFetchRecommendations(),
                child: const HomeScreen(),
              ),
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
              // 🎯 التعديل: كسر الكاش باستخدام pageBuilder
              pageBuilder: (context, state) => CustomTransitionPage(
                key: const ValueKey('my_applications_page'),
                child: BlocProvider.value(
                  value: sl<MyApplicationsCubit>(),
                  child: const MyApplicationsScreen(),
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => BlocProvider(
                create: (context) => sl<LogoutCubit>(),
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
