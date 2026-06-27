import 'package:get_it/get_it.dart';

import 'data/public_stats_feature.dart';

void registerMarketing(GetIt sl) {
  sl
    ..registerLazySingleton<PublicStatsRepository>(() => PublicStatsRepositoryImpl(sl()))
    ..registerFactory<PublicStatsCubit>(() => PublicStatsCubit(sl()));
}
