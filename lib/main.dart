import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/services/services_locator.dart' as di;
import 'package:germany_travel/firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/gamification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/widgets/connectivity_banner.dart';
import 'presentation/Home/cubit/home_cubit.dart';

class _NoOverscrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load();

  // Initialize Hive for local storage (fast — local IO only)
  await Hive.initFlutter();
  await LocalStorageService.init();

  // Supabase — wrapped in timeout in case of slow network
  try {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://marrlrggovghhnmhtbgs.supabase.co',
      ),
      publishableKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_72tk7ONyzJF9ZZAfVzX3Vw_woJVkEBe',
      ),
      debug: kDebugMode,
    ).timeout(const Duration(seconds: 10));
  } catch (_) {
    // Supabase init timed out — SplashScreen will retry
  }

  // Gamification (local — SharedPreferences)
  try {
    await GamificationService.init().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Non-critical
  }

  // Service Locator (synchronous — just registering lazy singletons)
  await di.init();

  // Show Flutter UI immediately — heavy init runs in background
  runApp(const MyApp());

  // ── Deferred init (non-blocking) ──
  _initDeferred();
}

Future<void> _initDeferred() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));

    // Crashlytics — non-fatal errors in production, disabled in debug
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      FlutterError.onError = (details) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (_) {
    // Firebase init failed — app works without it for now
  }

  try {
    await NotificationService.init().timeout(const Duration(seconds: 10));
    NotificationService.setRouter(appRouter);
  } catch (_) {
    // Notifications not critical for first launch
  }

  try {
    await ConnectivityService().init().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Will reconnect when connectivity changes
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeProvider _themeProvider;
  late final LanguageProvider _languageProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = di.sl<ThemeProvider>()..addListener(_onChanged);
    _languageProvider = di.sl<LanguageProvider>()..addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onChanged);
    _languageProvider.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(
          create: (context) =>
              di.sl<HomeCubit>()..calculateAndFetchRecommendations(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'UniPath',
            routerConfig: appRouter,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeProvider.themeMode,
            locale: _languageProvider.locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            builder: (context, widget) {
              return ScrollConfiguration(
                behavior: _NoOverscrollBehavior(),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: ConnectivityBanner(child: widget!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
