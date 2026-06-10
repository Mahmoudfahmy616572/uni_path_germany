import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import 'auth/auth_service.dart';

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
}
