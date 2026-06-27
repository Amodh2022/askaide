import 'package:get_it/get_it.dart';

import 'data/admin_feature.dart';

void registerAdmin(GetIt sl) {
  sl
    ..registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(sl()))
    ..registerFactory<AdminCubit>(() => AdminCubit(sl()));
}
