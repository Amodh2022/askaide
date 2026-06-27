import 'package:get_it/get_it.dart';

import 'data/quiz_repository.dart';
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
    ..registerFactory<QuizAnalyticsCubit>(() => QuizAnalyticsCubit(sl()));
}
