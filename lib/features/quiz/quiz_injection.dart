import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import 'data/quiz_repository.dart';
import 'presentation/cubit/countdown_cubit.dart';
import 'presentation/cubit/quiz_form_cubit.dart';
import 'presentation/cubit/quiz_history_search_cubit.dart';
import 'presentation/cubit/quiz_list_filter_cubit.dart';
import 'presentation/cubit/review_tile_cubit.dart';
import 'presentation/quiz_cubits.dart';
import 'presentation/quiz_teacher_cubits.dart';

void registerQuiz(GetIt sl) {
  sl
    ..registerLazySingleton<QuizRepository>(() => QuizRepositoryImpl(sl()))
    ..registerFactory<QuizListCubit>(() => QuizListCubit(sl()))
    ..registerFactory<QuizAttemptCubit>(() => QuizAttemptCubit(sl()))
    ..registerFactory<QuizResultCubit>(() => QuizResultCubit(sl()))
    ..registerFactory<TeacherQuizListCubit>(() => TeacherQuizListCubit(sl()))
    ..registerFactory<QuizBuilderCubit>(() => QuizBuilderCubit(sl(), sl()))
    ..registerFactory<QuizAnalyticsCubit>(() => QuizAnalyticsCubit(sl()))
    // ---- Widget-scoped cubits (fresh instance per widget mount) ----------
    ..registerFactory<QuizFormCubit>(QuizFormCubit.new)
    ..registerFactory<QuizListFilterCubit>(QuizListFilterCubit.new)
    ..registerFactory<QuizHistorySearchCubit>(QuizHistorySearchCubit.new)
    ..registerFactory<ReviewTileCubit>(ReviewTileCubit.new)
    ..registerFactoryParam<CountdownCubit, DateTime, VoidCallback>(
        (deadline, onExpire) => CountdownCubit(deadline, onExpire));
}
