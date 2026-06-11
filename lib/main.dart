import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/services/services_locator.dart' as di;
import 'package:germany_travel/firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/utils/app_router.dart';
import 'core/widgets/connectivity_banner.dart';
import 'presentation/Home/cubit/home_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await LocalStorageService.init();

  await Supabase.initialize(
    url: 'https://marrlrggovghhnmhtbgs.supabase.co',     // <-- Replace with your Supabase URL
    anonKey: 'sb_publishable_72tk7ONyzJF9ZZAfVzX3Vw_woJVkEBe', // <-- Replace with your Anon Key
    debug: true,
  );
  // Firebase init

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notifications & Connectivity
  await NotificationService.init();
  await di.init();
  NotificationService.setRouter(appRouter);
  await ConnectivityService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            theme: ThemeData(primarySwatch: Colors.indigo),
            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    1.0,
                  ),
                ),
                child: ConnectivityBanner(child: widget!),
              );
            },
          );
        },
      ),
    );
  }
}
