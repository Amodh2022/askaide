import 'package:get_it/get_it.dart';

import 'data/admin_feature.dart';
import 'presentation/cubit/admin_overview_cubit.dart';
import 'presentation/cubit/admin_picker_search_cubit.dart';
import 'presentation/cubit/admin_tab_cubit.dart';
import 'presentation/cubit/chapters_panel_cubit.dart';
import 'presentation/cubit/curriculum_panel_cubit.dart';
import 'presentation/cubit/mappings_panel_cubit.dart';
import 'presentation/cubit/relations_cubit.dart';
import 'presentation/cubit/schools_panel_cubit.dart';
import 'presentation/cubit/sections_panel_cubit.dart';
import 'presentation/cubit/students_panel_cubit.dart';
import 'presentation/cubit/teachers_panel_cubit.dart';
import 'presentation/cubit/topics_panel_cubit.dart';
import 'presentation/cubit/upload_chapter_cubit.dart';

void registerAdmin(GetIt sl) {
  sl
    ..registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(sl()))
    ..registerFactory<AdminCubit>(() => AdminCubit(sl()))
    // ---- Widget-scoped cubits (fresh instance per widget mount) ----------
    ..registerFactory<AdminTabCubit>(AdminTabCubit.new)
    ..registerFactory<AdminOverviewCubit>(() => AdminOverviewCubit(sl<AdminRepository>()))
    ..registerFactory<AdminPickerSearchCubit>(AdminPickerSearchCubit.new)
    ..registerFactory<ChaptersPanelCubit>(() => ChaptersPanelCubit(sl<AdminRepository>()))
    ..registerFactory<CurriculumPanelCubit>(() => CurriculumPanelCubit(sl<AdminRepository>()))
    ..registerFactory<MappingsPanelCubit>(() => MappingsPanelCubit(sl<AdminRepository>()))
    ..registerFactory<RelationsCubit>(() => RelationsCubit(sl<AdminRepository>()))
    ..registerFactory<SchoolsPanelCubit>(SchoolsPanelCubit.new)
    ..registerFactory<SectionsPanelCubit>(() => SectionsPanelCubit(sl<AdminRepository>()))
    ..registerFactory<StudentsPanelCubit>(StudentsPanelCubit.new)
    ..registerFactory<TopicsPanelCubit>(() => TopicsPanelCubit(sl<AdminRepository>()))
    ..registerFactory<UploadChapterCubit>(() => UploadChapterCubit(sl<AdminRepository>()))
    ..registerFactoryParam<TeachersPanelCubit, AdminCubit, void>(
        (admin, _) => TeachersPanelCubit(admin));
}
