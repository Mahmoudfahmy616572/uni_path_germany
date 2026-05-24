import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart'; // مسار الـ Repo
import '../../data/sources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../presentation/Home/cubit/home_cubit.dart';
import '../../presentation/auth/login/cubit/login_cubit.dart';
import '../../presentation/auth/logout/cubit/logout_cubit.dart';
import '../../presentation/auth/register/cubit/register_cubit.dart';
import 'auth/auth_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. الأساسيات (Supabase & AuthService)
  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => AuthService(sl()));

  // 2. الـ Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // 3. الـ Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // 4. الـ Cubits
  sl.registerFactory(() => HomeCubit());
  sl.registerFactory(() => LoginCubit(sl()));
  sl.registerFactory(() => RegisterCubit(sl()));
  sl.registerFactory(() => LogoutCubit(sl()));
}
