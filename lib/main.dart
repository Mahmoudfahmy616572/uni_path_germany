import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/services/services_locator.dart' as di;
import 'package:germany_travel/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/notification_service.dart';
import 'core/utils/app_router.dart';
import 'presentation/Home/cubit/home_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://marrlrggovghhnmhtbgs.supabase.co',
    anonKey: 'sb_publishable_72tk7ONyzJF9ZZAfVzX3Vw_woJVkEBe',
    debug: true,
  );
  // Firebase init

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notifications
  await NotificationService.init();
  await di.init();
  NotificationService.setRouter(appRouter);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
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
                child: widget!,
              );
            },
          );
        },
      ),
    );
  }
}
