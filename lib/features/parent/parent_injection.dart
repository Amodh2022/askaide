import 'package:get_it/get_it.dart';

import 'parent_feature.dart';

void registerParent(GetIt sl) {
  sl
    ..registerLazySingleton<ParentRepository>(() => ParentRepositoryImpl(sl()))
    ..registerFactory<ParentCubit>(() => ParentCubit(sl()));
}
