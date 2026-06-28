import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show SystemNavigator;

import '../../core/localization/app_localizations.dart';

import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/auth/go_router_refresh_stream.dart';
import 'logger.dart';
import '../../domain/entities/university_entity.dart';
import '../../presentation/Home/screen/home_screen.dart';
import '../../presentation/splash/screens/splash_screen.dart';
import '../../presentation/MyApplications/cubit/my_applications_cubits.dart';
import '../../presentation/MyApplications/cubit/my_applications_states.dart';
import '../../presentation/MyApplications/screens/my_applications_screen.dart';
import '../../presentation/UniversityDetails/screens/university_details_screen.dart';
import '../../presentation/auth/forgot_password/screen/forgot_password_screen.dart';
import '../../presentation/auth/reset_password/screen/reset_password_screen.dart';
import '../../presentation/auth/verify_email/screen/verify_email_screen.dart';
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
import '../../presentation/premium/screen/paywall_screen.dart';
import '../../presentation/ai/widgets/document_templates_screen.dart';
import '../../presentation/applications/screens/deadline_calendar_screen.dart';
import '../../presentation/comparison/screens/university_comparison_screen.dart';
import '../../presentation/documents/smart_document_hub_screen.dart';
import '../../presentation/search/screen/university_search_screen.dart';
import '../../presentation/policy/policy_viewer_screen.dart';
import '../../presentation/ai/widgets/uni_match_screen.dart';
import '../../presentation/applications/widgets/application_timeline_screen.dart';
import '../../presentation/documents/visa_guide_screen.dart';
import '../../presentation/profile/gamification_screen.dart';
import '../../presentation/cost_of_living/screens/cost_of_living_screen.dart';
import '../services/services_locator.dart';
import '../utils/policy_content.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');



final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
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
        currentLocation != '/forgot-password' &&
        currentLocation != '/reset-password' &&
        currentLocation != '/verify-email' &&
        currentLocation != '/onboarding' &&
        currentLocation != '/splash') {
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
            currentLocation == '/splash' ||
            currentLocation == '/')) {
      // Don't redirect away from /register during OAuth — the cubit needs to stay alive
      if (currentLocation == '/register' && AuthService.isOAuthInProgress) {
        log.i('OAuth pending — staying on /register');
        return null;
      }
      if (currentLocation == '/splash') {
        log.i('Staying on /splash');
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
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
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
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => BlocProvider.value(
        value: sl<LoginCubit>(),
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordScreen(
        code: state.uri.queryParameters['code'],
      ),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => VerifyEmailScreen(
        email: state.uri.queryParameters['email'],
      ),
    ),

    // 🎯 إصلاح مسار شاشة الإعدادات
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final profileCubit = state.extra is ProfileCubit ? state.extra as ProfileCubit : sl<ProfileCubit>();
        final section = int.tryParse(state.uri.queryParameters['section'] ?? '');
        return _SettingsRouteHandler(cubit: profileCubit, scrollToSection: section);
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
      path: '/smart-documents',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SmartDocumentHubScreen(),
    ),

    GoRoute(
      path: '/university_details',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: UniversityDetailsScreen(university: state.extra as UniversityEntity),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.25, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),

    GoRoute(
      path: '/premium',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PaywallScreen(),
    ),
    GoRoute(
      path: '/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final locale = AppLocalizations.of(context).locale;
        return PolicyViewerScreen(
          title: 'Privacy Policy',
          content: PolicyContent.getPrivacyPolicy(locale.languageCode),
        );
      },
    ),
    GoRoute(
      path: '/terms',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final locale = AppLocalizations.of(context).locale;
        return PolicyViewerScreen(
          title: 'Terms of Service',
          content: PolicyContent.getTermsOfService(locale.languageCode),
        );
      },
    ),

    GoRoute(
      path: '/deadline-calendar',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final cubit = sl<MyApplicationsCubit>();
        final s = cubit.state;
        if (s is MyApplicationsLoaded) {
          return DeadlineCalendarScreen(applications: s.allApplications);
        }
        return const Scaffold(
          body: Center(child: Text('No application data loaded')),
        );
      },
    ),

    GoRoute(
      path: '/compare',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final universities = state.extra as List<UniversityEntity>? ?? [];
        return UniversityComparisonScreen(universities: universities);
      },
    ),

    GoRoute(
      path: '/document-templates',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DocumentTemplatesScreen(),
    ),

    GoRoute(
      path: '/uni-match',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UniMatchScreen(),
    ),
    GoRoute(
      path: '/application-timeline',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final cubit = sl<MyApplicationsCubit>();
        final s = cubit.state;
        if (s is MyApplicationsLoaded) {
          return BlocProvider.value(
            value: cubit,
            child: ApplicationTimelineScreen(applications: s.allApplications),
          );
        }
        return const Scaffold(
          body: Center(child: Text('No application data loaded')),
        );
      },
    ),
    GoRoute(
      path: '/visa-guide',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VisaGuideScreen(),
    ),
    GoRoute(
      path: '/cost-of-living',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => CostOfLivingScreen(
        initialCity: state.uri.queryParameters['city'],
      ),
    ),
    GoRoute(
      path: '/achievements',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GamificationScreen(),
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
      builder: (context, state, navigationShell) => _MainShell(
        navigationShell: navigationShell,
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
  final int? scrollToSection;
  const _SettingsRouteHandler({required this.cubit, this.scrollToSection});

  @override
  State<_SettingsRouteHandler> createState() => _SettingsRouteHandlerState();
}

class _SettingsRouteHandlerState extends State<_SettingsRouteHandler> {
  ProfileLoaded? _lastLoaded;

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
            _lastLoaded = state;
            return SettingsScreen(user: state.user, scrollToSection: widget.scrollToSection);
          }
          if (state is ProfileUpdateSuccess && _lastLoaded != null) {
            return SettingsScreen(user: _lastLoaded!.user, scrollToSection: widget.scrollToSection);
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

class _MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const _MainShell({required this.navigationShell});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  DateTime? _lastBackPress;

  void _onBottomNavTap(int index) {
    if (index == 2) sl<MyApplicationsCubit>().loadApplications();

    if (index == 0 && index == widget.navigationShell.currentIndex) {
      HomeScreen.scrollController?.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('pressAgainToExit'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          type: BottomNavigationBarType.fixed,
          onTap: _onBottomNavTap,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: AppLocalizations.of(context).translate('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: AppLocalizations.of(context).translate('search'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.description_outlined),
              label: AppLocalizations.of(context).translate('applications'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: AppLocalizations.of(context).translate('profile'),
            ),
          ],
        ),
      ),
    );
  }
}
