import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'data/public_stats_feature.dart';
import 'presentation/cubit/feedback_form_cubit.dart';
import 'presentation/cubit/public_profile_cubit.dart';

void registerMarketing(GetIt sl) {
  sl
    ..registerLazySingleton<PublicStatsRepository>(() => PublicStatsRepositoryImpl(sl()))
    ..registerFactory<PublicStatsCubit>(() => PublicStatsCubit(sl()))
    // ---- Widget-scoped cubits (fresh instance per widget mount) ----------
    ..registerFactory<MarketingFeedbackCubit>(() => MarketingFeedbackCubit(sl<Dio>()))
    ..registerFactory<PublicProfileCubit>(() => PublicProfileCubit(sl<Dio>()));
}
