import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/services/services_locator.dart' as di;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utils/app_router.dart';
import 'presentation/Home/cubit/home_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://marrlrggovghhnmhtbgs.supabase.co',
    anonKey: 'sb_publishable_72tk7ONyzJF9ZZAfVzX3Vw_woJVkEBe',
  );
  await di.init();
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
      // 🎯 تغليف الـ ScreenUtilInit هنا هو اللي بيحمي الأبلكيشن كله من الكراش
      child: ScreenUtilInit(
        designSize: const Size(462, 975), // 👈 اكتب مقاس شاشتك الحالية هنا
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'UniPath',
            routerConfig: appRouter,
            theme: ThemeData(primarySwatch: Colors.indigo),
            // 🎯 السطر السحري ده بيثبت حجم الخطوط في الأبلكيشن كله لأي جهاز
            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    1.2,
                  ), // 👈 يمنع تغيير حجم الخطوط من إعدادات الهاتف
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
