import 'package:get_it/get_it.dart';

import 'data/dashboard_repository.dart';
import 'data/progress_repository.dart';
import 'presentation/cubit/dashboard_cubit.dart';
import 'presentation/cubit/progress_cubit.dart';

void registerDashboard(GetIt sl) {
  sl
    ..registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(sl()))
    ..registerFactory<DashboardCubit>(() => DashboardCubit(sl()))
    ..registerLazySingleton<ProgressRepository>(() => ProgressRepositoryImpl(sl()))
    ..registerFactory<ProgressCubit>(() => ProgressCubit(sl()));
}
