import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:germany_travel/core/services/auth/auth_service.dart';
import 'package:germany_travel/core/services/auth/go_router_refresh_stream.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/Home/cubit/home_cubit.dart';
import '../../presentation/Home/screen/home_screen.dart';
import '../../presentation/auth/login/cubit/login_cubit.dart';
import '../../presentation/auth/login/screen/login_screen.dart';
import '../../presentation/auth/register/cubit/register_cubit.dart';
import '../../presentation/auth/register/screen/register_screen.dart';
import '../services/services_locator.dart';

final GoRouter appRouter = GoRouter(
  refreshListenable: GoRouterRefreshStream(sl<AuthService>().authStateChanges),

  redirect: (context, state) {
    // بنجيب حالة الـ Auth من الـ AuthService
    final bool isLoggedIn =
        Supabase.instance.client.auth.currentSession != null;
    // هل اليوزر حالياً في شاشات الـ Auth؟
    final bool isGoingToAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    // 1. لو مش مسجل دخول ورايح لصفحة محمية -> وّديه للـ Login
    if (!isLoggedIn && !isGoingToAuth) return '/login';
    // 2. لو مسجل دخول ورايح لصفحة الـ Auth -> وّديه للـ Home (/)
    if (isLoggedIn && isGoingToAuth) return '/';

    return null; // كمل في طريقك عادي
  },
  routes: [
    // روت الـ Login
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<LoginCubit>(), // هنحتاج Cubit للـ Login
        child: LoginScreen(),
      ),
    ),

    // روت الـ Register
    GoRoute(
      path: '/register',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<RegisterCubit>(), // هنحتاج Cubit للـ Register
        child: RegisterScreen(),
      ),
    ),

    // روت الـ Home
    GoRoute(
      path: '/',
      builder: (context, state) => BlocProvider(
        create: (context) =>
            sl<HomeCubit>()..calculateAndFetchRecommendations(72),
        child: const HomeScreen(),
      ),
    ),
  ],
);
