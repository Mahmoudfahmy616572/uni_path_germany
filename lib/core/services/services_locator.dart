import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

import '../../data/repositories/applications_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/universities_repository_impl.dart';
import '../../data/sources/applications_remote_data_source.dart';
import '../../data/sources/auth_remote_data_source.dart';
import '../../data/sources/universities_remote_data_source.dart';
import '../../domain/repositories/applications_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/universities_repository.dart';
import '../../presentation/Home/cubit/home_cubit.dart';
import '../../presentation/MyApplications/cubit/my_applications_cubits.dart';
import '../../presentation/UniversityDetails/cubit/university_details_cubit.dart';
import '../../presentation/auth/login/cubit/login_cubit.dart';
import '../../presentation/auth/logout/cubit/logout_cubit.dart';
import '../../presentation/auth/register/cubit/register_cubit.dart';
// 🎯 استيراد الكيوبيت الجديد
import '../../presentation/profile/cubit/profile_cubit.dart';
import 'ai/ai_usage_service.dart';
import 'ai/gemini_service.dart';
import 'ai/review_cache_service.dart';
import 'auth/auth_service.dart';
import 'email_tracking/email_connection_service.dart';
import 'paymob_service.dart';
import 'premium_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. الأساسيات
  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => AuthService(sl()));

  // 2. الـ Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<UniversitiesRemoteDataSource>(
    () => UniversitiesRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ApplicationsRemoteDataSource>(
    () => ApplicationsRemoteDataSourceImpl(sl()),
  );

  // 3. الـ Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<ApplicationsRepository>(
    () => ApplicationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<UniversitiesRepository>(
    () => UniversitiesRepositoryImpl(sl(), sl()),
  );

  // 4. الـ Cubits
  sl.registerFactory(() => ProfileCubit(sl(), sl())); // 🎯 جديد
  sl.registerLazySingleton(() => HomeCubit(sl()));
  sl.registerLazySingleton(() => LoginCubit(sl()));
  sl.registerLazySingleton(() => RegisterCubit(sl(), sl()));
  sl.registerLazySingleton(() => LogoutCubit(sl()));
  sl.registerLazySingleton(() => UniversityDetailsCubit(sl()));
  sl.registerLazySingleton(() => MyApplicationsCubit(sl()));

  // 5. App Providers
  sl.registerLazySingleton(() => ThemeProvider());
  sl.registerLazySingleton(() => LanguageProvider());

  // 6. Email Tracking
  sl.registerLazySingleton(() => EmailConnectionService(sl()));

  // 7. Premium Service
  sl.registerLazySingleton(() => PremiumService(sl()));

  // 7b. Paymob Payment Service
  sl.registerLazySingleton(() => PaymobService(
    Dio(),
    dotenv.env['SUPABASE_URL'] ?? '',
    sl(),
  ));

  // 8. AI Services
  sl.registerLazySingleton(() => GeminiService(
    apiKey: dotenv.env['GEMINI_API_KEY'],
    serverUrl: dotenv.env['SERVER_URL'],
  ));
  sl.registerLazySingleton(() => AiUsageService(sl(), sl()));
  sl.registerLazySingleton(() => ReviewCacheService());
}
