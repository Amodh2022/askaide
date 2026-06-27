import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/admin/data/admin_feature.dart';
import '../../features/ai_assistant/ai_assistant_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/dashboard/data/progress_repository.dart';
import '../../features/parent/parent_feature.dart';
import '../../features/question_paper/data/question_paper_feature.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/dashboard/presentation/cubit/progress_cubit.dart';
import '../../features/quiz/data/quiz_repository.dart';
import '../../features/quiz/presentation/quiz_cubits.dart';
import '../../features/quiz/presentation/quiz_teacher_cubits.dart';
import '../../features/marketing/data/public_stats_feature.dart';
import '../../features/referral/referral_feature.dart';
import '../../features/teacher/data/teacher_feature.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_user_details.dart';
import '../../features/profile/domain/usecases/profile_actions.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/session/data/datasources/session_local_datasource.dart';
import '../../features/session/data/datasources/session_remote_datasource.dart';
import '../../features/session/data/repositories/session_repository_impl.dart';
import '../../features/session/domain/repositories/session_repository.dart';
import '../../features/session/domain/usecases/session_usecases.dart';
import '../../features/session/presentation/bloc/session_bloc.dart';
import '../network/dio_client.dart';
import '../sound/sound_cubit.dart';
import '../sound/sound_service.dart';
import '../taxonomy/taxonomy_repository.dart';
import '../network/network_info.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../theme/theme_cubit.dart';

/// Service locator. `configureDependencies` is called once during bootstrap,
/// after [LocalStorageService.init] has opened the Hive boxes.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies(LocalStorageService localStorage) async {
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

  _registerAuth();
  _registerProfile();
  _registerSession();
  _registerDashboard();
  _registerQuiz();
  sl
    ..registerLazySingleton<ReferralRepository>(() => ReferralRepositoryImpl(sl()))
    ..registerFactory<ReferralCubit>(() => ReferralCubit(sl()))
    ..registerLazySingleton<TeacherRepository>(() => TeacherRepositoryImpl(sl()))
    ..registerFactory<TeacherHomeCubit>(() => TeacherHomeCubit(sl()))
    ..registerFactory<TeacherSubjectCubit>(() => TeacherSubjectCubit(sl()))
    ..registerFactory<TeacherStudentCubit>(() => TeacherStudentCubit(sl()))
    ..registerFactory<TeacherStudentsCubit>(() => TeacherStudentsCubit(sl()))
    ..registerFactory<TeacherChapterCubit>(() => TeacherChapterCubit(sl()))
    ..registerFactory<TeacherWeakTopicsCubit>(() => TeacherWeakTopicsCubit(sl()))
    ..registerFactory<TeacherActivityCubit>(() => TeacherActivityCubit(sl()))
    ..registerLazySingleton<ParentRepository>(() => ParentRepositoryImpl(sl()))
    ..registerFactory<ParentCubit>(() => ParentCubit(sl()))
    ..registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(sl()))
    ..registerFactory<AdminCubit>(() => AdminCubit(sl()))
    ..registerLazySingleton<TaxonomyRepository>(() => TaxonomyRepository(sl()))
    ..registerLazySingleton<QuestionPaperRepository>(() => QuestionPaperRepositoryImpl(sl()))
    ..registerFactory<PaperPreviewCubit>(() => PaperPreviewCubit(sl()))
    ..registerFactory<PaperHistoryCubit>(() => PaperHistoryCubit(sl()))
    ..registerFactory<QpGeneratorCubit>(() => QpGeneratorCubit(sl(), sl(), sl()))
    ..registerFactory<PublicQpCubit>(() => PublicQpCubit(sl(), sl()))
    ..registerLazySingleton<AiAssistantRepository>(() => AiAssistantRepository(sl()))
    ..registerLazySingleton<PublicStatsRepository>(() => PublicStatsRepositoryImpl(sl()))
    ..registerFactory<PublicStatsCubit>(() => PublicStatsCubit(sl()));

  // ---- App-global cubits --------------------------------------------------
  sl
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()))
    ..registerLazySingleton<SoundService>(() => SoundService(sl()))
    ..registerLazySingleton<SoundCubit>(() => SoundCubit(sl(), sl()));
}

void _registerDashboard() {
  sl
    ..registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(sl()))
    ..registerFactory<DashboardCubit>(() => DashboardCubit(sl()))
    ..registerLazySingleton<ProgressRepository>(() => ProgressRepositoryImpl(sl()))
    ..registerFactory<ProgressCubit>(() => ProgressCubit(sl()));
}

void _registerQuiz() {
  sl
    ..registerLazySingleton<QuizRepository>(() => QuizRepositoryImpl(sl()))
    ..registerFactory<QuizListCubit>(() => QuizListCubit(sl()))
    ..registerFactory<QuizAttemptCubit>(() => QuizAttemptCubit(sl()))
    ..registerFactory<QuizResultCubit>(() => QuizResultCubit(sl()))
    ..registerFactory<TeacherQuizListCubit>(() => TeacherQuizListCubit(sl()))
    ..registerFactory<QuizBuilderCubit>(() => QuizBuilderCubit(sl(), sl()))
    ..registerFactory<QuizAnalyticsCubit>(() => QuizAnalyticsCubit(sl()));
}

void _registerAuth() {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remote: sl(), storage: sl()))
    ..registerLazySingleton(() => Login(sl()))
    ..registerLazySingleton(() => LoginWithGoogle(sl()))
    ..registerLazySingleton(() => SendOtp(sl()))
    ..registerLazySingleton(() => Signup(sl()))
    ..registerLazySingleton(() => RequestPasswordReset(sl()))
    ..registerLazySingleton(() => ResetPassword(sl()))
    ..registerLazySingleton(() => Logout(sl()))
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        repository: sl(),
        login: sl(),
        loginWithGoogle: sl(),
        sendOtp: sl(),
        signup: sl(),
        requestPasswordReset: sl(),
        resetPassword: sl(),
        logout: sl(),
      ),
    );
}

void _registerProfile() {
  sl
    ..registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetUserDetails(sl()))
    ..registerLazySingleton(() => UpdateProfile(sl()))
    ..registerLazySingleton(() => ChangePassword(sl()))
    ..registerLazySingleton(() => UpdateDisplayPicture(sl()))
    ..registerLazySingleton(() => DeleteProfilePhoto(sl()))
    ..registerLazySingleton(() => DeleteProfile(sl()))
    ..registerLazySingleton<ProfileCubit>(
      () => ProfileCubit(
        getUserDetails: sl(),
        updateProfile: sl(),
        changePassword: sl(),
      ),
    );
}

void _registerSession() {
  sl
    ..registerLazySingleton<SessionRemoteDataSource>(
        () => SessionRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<SessionLocalDataSource>(
        () => SessionLocalDataSourceImpl(sl()))
    ..registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(remote: sl(), local: sl(), networkInfo: sl()),
    )
    ..registerLazySingleton(() => GetClasses(sl()))
    ..registerLazySingleton(() => GetSubjects(sl()))
    ..registerLazySingleton(() => GetChapters(sl()))
    ..registerLazySingleton(() => FetchQuestionBatch(sl()))
    ..registerLazySingleton(() => SubmitAnswers(sl()))
    ..registerLazySingleton(() => SyncQueuedAnswers(sl()))
    ..registerLazySingleton(() => SaveSession(sl()))
    ..registerLazySingleton<SessionBloc>(
      () => SessionBloc(
        repository: sl(),
        getClasses: sl(),
        getSubjects: sl(),
        getChapters: sl(),
        fetchQuestionBatch: sl(),
        submitAnswers: sl(),
        syncQueuedAnswers: sl(),
        saveSession: sl(),
        networkInfo: sl(),
      ),
    );
}
