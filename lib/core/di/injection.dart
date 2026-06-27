import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/admin/admin_injection.dart';
import '../../features/ai_assistant/ai_assistant_injection.dart';
import '../../features/auth/auth_injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/dashboard_injection.dart';
import '../../features/marketing/marketing_injection.dart';
import '../../features/parent/parent_injection.dart';
import '../../features/profile/profile_injection.dart';
import '../../features/question_paper/question_paper_injection.dart';
import '../../features/quiz/quiz_injection.dart';
import '../../features/referral/referral_injection.dart';
import '../../features/session/session_injection.dart';
import '../../features/teacher/teacher_injection.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../sound/sound_cubit.dart';
import '../sound/sound_service.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../taxonomy/taxonomy_repository.dart';
import '../theme/theme_cubit.dart';

/// Service locator. `configureDependencies` is called once during bootstrap,
/// after [LocalStorageService.init] has opened the Hive boxes.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies(LocalStorageService localStorage) async {
  registerCore(sl, localStorage);

  registerAuth(sl);
  registerProfile(sl);
  registerSession(sl);
  registerDashboard(sl);
  registerQuiz(sl);
  registerReferral(sl);
  registerTeacher(sl);
  registerParent(sl);
  registerAdmin(sl);
  registerQuestionPaper(sl);
  registerAiAssistant(sl);
  registerMarketing(sl);

  // ---- App-global cubits --------------------------------------------------
  sl
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()))
    ..registerLazySingleton<SoundService>(() => SoundService(sl()))
    ..registerLazySingleton<SoundCubit>(() => SoundCubit(sl(), sl()));
}

/// Core / external services plus the cross-cutting [TaxonomyRepository].
/// Registered before any feature so feature dependencies resolve.
void registerCore(GetIt sl, LocalStorageService localStorage) {
  // ---- External / core services -----------------------------------------
  sl
    ..registerSingleton<LocalStorageService>(localStorage)
    ..registerLazySingleton<FlutterSecureStorage>(
        () => const FlutterSecureStorage())
    ..registerLazySingleton<SecureStorageService>(
        () => SecureStorageServiceImpl(sl()))
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    ..registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Dio: a 401 forces logout via the (lazily-resolved) AuthBloc.
  sl.registerLazySingleton<Dio>(
    () => DioClient.create(
      storage: sl(),
      onUnauthorized: () {
        if (sl.isRegistered<AuthBloc>()) {
          sl<AuthBloc>().add(const AuthForcedLogout());
        }
      },
    ),
  );

  // Taxonomy is consumed by QuestionPaper (QpGeneratorCubit/PublicQpCubit).
  sl.registerLazySingleton<TaxonomyRepository>(() => TaxonomyRepository(sl()));
}
