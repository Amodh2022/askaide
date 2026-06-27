import 'package:get_it/get_it.dart';

import 'referral_feature.dart';

void registerReferral(GetIt sl) {
  sl
    ..registerLazySingleton<ReferralRepository>(() => ReferralRepositoryImpl(sl()))
    ..registerFactory<ReferralCubit>(() => ReferralCubit(sl()));
}
