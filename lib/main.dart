import 'package:flutter/material.dart';
import 'package:germany_travel/core/services/services_locator.dart' as di;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utils/app_router.dart';

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
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'UniPath',
      routerConfig: appRouter,
      theme: ThemeData(primarySwatch: Colors.indigo),
    );
  }
}
