import 'package:get_it/get_it.dart';

import 'data/datasources/session_local_datasource.dart';
import 'data/datasources/session_remote_datasource.dart';
import 'data/repositories/session_repository_impl.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/usecases/session_usecases.dart';
import 'presentation/bloc/session_bloc.dart';

void registerSession(GetIt sl) {
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
