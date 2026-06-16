import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/services/services_locator.dart' as di;
import 'package:germany_travel/firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Device language detection
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('app_locale');
  if (savedLocale == null) {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    await prefs.setString(
      'app_locale',
      deviceLocale.languageCode == 'ar' ? 'ar' : 'en',
    );
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await LocalStorageService.init();

  await Supabase.initialize(
    url:
        'https://marrlrggovghhnmhtbgs.supabase.co', // <-- Replace with your Supabase URL
    publishableKey:
        'sb_publishable_72tk7ONyzJF9ZZAfVzX3Vw_woJVkEBe', // <-- Replace with your Anon Key
    debug: true,
  );
  // Firebase init

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Service Locator first (so AuthService & others are ready)
  await di.init();
  // Notifications & Connectivity
  await NotificationService.init();
  NotificationService.setRouter(appRouter);
  await ConnectivityService().init();
  runApp(const MyApp());
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
