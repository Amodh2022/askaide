import 'package:get_it/get_it.dart';

import 'data/datasources/session_local_datasource.dart';
import 'data/datasources/session_remote_datasource.dart';
import 'data/repositories/session_repository_impl.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/usecases/session_usecases.dart';
import 'presentation/bloc/session_bloc.dart';
import 'presentation/cubit/feedback_form_cubit.dart';
import 'presentation/cubit/generating_message_cubit.dart';
import 'presentation/cubit/nps_survey_cubit.dart';
import 'presentation/cubit/picker_search_cubit.dart';
import 'presentation/cubit/practice_ui_cubit.dart';
import 'presentation/cubit/typewriter_cubit.dart';

void registerSession(GetIt sl) {
  sl
    ..registerLazySingleton<SessionRemoteDataSource>(
        () => SessionRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<SessionLocalDataSource>(
        () => SessionLocalDataSourceImpl(sl()))
    ..registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(
          remote: sl(), local: sl(), networkInfo: sl(), taxonomy: sl()),
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
    )
    // ---- Widget-scoped cubits (fresh instance per widget mount) ----------
    ..registerFactory<NpsSurveyCubit>(NpsSurveyCubit.new)
    ..registerFactory<PracticeUiCubit>(PracticeUiCubit.new)
    ..registerFactory<PickerSearchCubit>(PickerSearchCubit.new)
    ..registerFactory<FeedbackFormCubit>(
        () => FeedbackFormCubit(sl<SessionRepository>()))
    ..registerFactoryParam<GeneratingMessageCubit, int, void>(
        (messageCount, _) => GeneratingMessageCubit(messageCount))
    ..registerFactoryParam<TypewriterCubit, int, void>(
        (textLength, _) => TypewriterCubit(textLength));
}
