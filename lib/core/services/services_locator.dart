import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// الـ Repositories Implementations
import '../../data/repositories/applications_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/universities_repository_impl.dart';
// الـ Data Sources
import '../../data/sources/applications_remote_data_source.dart';
import '../../data/sources/auth_remote_data_source.dart';
import '../../data/sources/universities_remote_data_source.dart';
// الـ Repositories Contracts
import '../../domain/repositories/applications_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/universities_repository.dart';
// الـ Cubits
import '../../presentation/Home/cubit/home_cubit.dart';
import '../../presentation/MyApplications/cubit/my_applications_cubits.dart';
import '../../presentation/UniversityDetails/cubit/university_details_cubit.dart';
import '../../presentation/auth/login/cubit/login_cubit.dart';
import '../../presentation/auth/logout/cubit/logout_cubit.dart';
import '../../presentation/auth/register/cubit/register_cubit.dart';
import 'auth/auth_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. الأساسيات (Supabase Client & AuthService)
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
  sl.registerLazySingleton(() => HomeCubit(sl<UniversitiesRepository>()));
  sl.registerLazySingleton(() => LoginCubit(sl<AuthRepository>()));
  sl.registerLazySingleton(
    () => RegisterCubit(sl<AuthRepository>(), sl<UniversitiesRepository>()),
  );

  sl.registerLazySingleton(() => LogoutCubit(sl()));
  // sl.registerLazySingleton(
  //   () => CompleteProfileCubit(sl<UniversitiesRepository>()),
  // );
  sl.registerLazySingleton(
    () => UniversityDetailsCubit(sl<ApplicationsRepository>()),
  );
  sl.registerLazySingleton(
    () =>
        MyApplicationsCubit(sl<ApplicationsRepository>(), sl<AuthRepository>()),
  );
}
