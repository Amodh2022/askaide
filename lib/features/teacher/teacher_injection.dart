import 'package:get_it/get_it.dart';

import '../ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'data/teacher_feature.dart';
import 'presentation/cubit/chapter_accordion_cubit.dart';
import 'presentation/cubit/student_filter_cubit.dart';
import 'presentation/cubit/teacher_ai_generator_cubit.dart';

void registerTeacher(GetIt sl) {
  sl
    ..registerLazySingleton<TeacherRepository>(() => TeacherRepositoryImpl(sl()))
    ..registerFactory<TeacherHomeCubit>(() => TeacherHomeCubit(sl()))
    ..registerFactory<TeacherSubjectCubit>(() => TeacherSubjectCubit(sl()))
    ..registerFactory<TeacherStudentCubit>(() => TeacherStudentCubit(sl()))
    ..registerFactory<TeacherStudentsCubit>(() => TeacherStudentsCubit(sl()))
    ..registerFactory<TeacherChapterCubit>(() => TeacherChapterCubit(sl()))
    ..registerFactory<TeacherWeakTopicsCubit>(() => TeacherWeakTopicsCubit(sl()))
    ..registerFactory<TeacherActivityCubit>(() => TeacherActivityCubit(sl()))
    // ---- Widget-scoped cubits (fresh instance per widget mount) ----------
    ..registerFactory<TeacherAiGeneratorCubit>(
        () => TeacherAiGeneratorCubit(sl<AiTeacherToolsRepository>()))
    ..registerFactory<ChapterAccordionCubit>(ChapterAccordionCubit.new)
    ..registerFactory<StudentFilterCubit>(StudentFilterCubit.new);
}
