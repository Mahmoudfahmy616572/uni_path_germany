import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/localization/app_localizations.dart';

import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/auth/go_router_refresh_stream.dart';
import 'logger.dart';
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
import '../../presentation/profile/widgets/email_tracking_screen.dart';
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

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');



final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  refreshListenable: GoRouterRefreshStream(sl<AuthService>().authStateChanges),
  redirect: (context, state) {
    // Synchronous check for redirect
    final session = Supabase.instance.client.auth.currentSession;
    final bool isLoggedIn = session != null;
    final String currentLocation = state.matchedLocation;

    log.i('ROUTER REDIRECT: location=$currentLocation, isLoggedIn=$isLoggedIn');

    if (!isLoggedIn &&
        currentLocation != '/login' &&
        currentLocation != '/register' &&
        currentLocation != '/onboarding') {
      // During OAuth, send deep link back to /register where the listener is
      if (currentLocation == '/' && AuthService.isOAuthInProgress) {
        log.i('OAuth pending — returning to /register');
        return '/register';
      }
      log.i('REDIRECT -> /login');
      return '/login';
    }
    if (isLoggedIn &&
        (currentLocation == '/login' ||
            currentLocation == '/register' ||
            currentLocation == '/onboarding' ||
            currentLocation == '/')) {
      // Don't redirect away from /register during OAuth — the cubit needs to stay alive
      if (currentLocation == '/register' && AuthService.isOAuthInProgress) {
        log.i('OAuth pending — staying on /register');
        return null;
      }
      log.i('REDIRECT -> /home');
      return '/home';
    }
    log.i('NO REDIRECT');
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
      builder: (context, state) => BlocProvider.value(
        value: sl<LoginCubit>(),
        child: LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => BlocProvider.value(
        value: sl<RegisterCubit>(),
        child: RegisterScreen(
          profileData: state.extra as Map<String, dynamic>?,
        ),
      ),
    ),

    // 🎯 إصلاح مسار شاشة الإعدادات
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final profileCubit = state.extra as ProfileCubit;
        return _SettingsRouteHandler(cubit: profileCubit);
      },
    ),

    GoRoute(
      path: '/email-tracking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EmailTrackingScreen(),
    ),

    GoRoute(
      path: '/documents',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final entity = state.extra;
        if (entity is! UniversityEntity) {
          return const Scaffold(
            body: Center(child: Text('No document data available')),
          );
        }
        return DocumentsScreen(userFiles: entity);
      },
    ),

    GoRoute(
      path: '/university_details',
      parentNavigatorKey: _rootNavigatorKey,
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
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 2) sl<MyApplicationsCubit>().loadApplications();
            navigationShell.goBranch(index);
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: AppLocalizations.of(context).translate('home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: AppLocalizations.of(context).translate('search'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              label: AppLocalizations.of(context).translate('applications'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: AppLocalizations.of(context).translate('profile'),
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

// ─────────────────────────────────────────────────────────
// Settings route wrapper — loads profile if not already loaded
// ─────────────────────────────────────────────────────────
class _SettingsRouteHandler extends StatefulWidget {
  final ProfileCubit cubit;
  const _SettingsRouteHandler({required this.cubit});

  @override
  State<_SettingsRouteHandler> createState() => _SettingsRouteHandlerState();
}

class _SettingsRouteHandlerState extends State<_SettingsRouteHandler> {
  @override
  void initState() {
    super.initState();
    final s = widget.cubit.state;
    if (s is! ProfileLoaded && s is! ProfileLoading) {
      widget.cubit.getUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoaded) {
            return SettingsScreen(user: state.user);
          }
          if (state is ProfileError) {
            return Scaffold(
              appBar: AppBar(title: Text(AppLocalizations.of(context).translate('settings'))),
              body: Center(child: Text('Error: ${state.message}')),
            );
          }
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).translate('settings'))),
            body: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
