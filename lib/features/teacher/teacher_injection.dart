import 'package:get_it/get_it.dart';

import 'data/teacher_feature.dart';

void registerTeacher(GetIt sl) {
  sl
    ..registerLazySingleton<TeacherRepository>(() => TeacherRepositoryImpl(sl()))
    ..registerFactory<TeacherHomeCubit>(() => TeacherHomeCubit(sl()))
    ..registerFactory<TeacherSubjectCubit>(() => TeacherSubjectCubit(sl()))
    ..registerFactory<TeacherStudentCubit>(() => TeacherStudentCubit(sl()))
    ..registerFactory<TeacherStudentsCubit>(() => TeacherStudentsCubit(sl()))
    ..registerFactory<TeacherChapterCubit>(() => TeacherChapterCubit(sl()))
    ..registerFactory<TeacherWeakTopicsCubit>(() => TeacherWeakTopicsCubit(sl()))
    ..registerFactory<TeacherActivityCubit>(() => TeacherActivityCubit(sl()));
}
