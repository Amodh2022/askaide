import 'package:get_it/get_it.dart';

import 'data/question_paper_feature.dart';

/// Registers QuestionPaper services. Depends on `TaxonomyRepository` and
/// `QuestionPaperRepository` (resolved lazily) for QpGeneratorCubit/PublicQpCubit,
/// so core taxonomy registration must run before these are constructed.
void registerQuestionPaper(GetIt sl) {
  sl
    ..registerLazySingleton<QuestionPaperRepository>(() => QuestionPaperRepositoryImpl(sl()))
    ..registerFactory<PaperPreviewCubit>(() => PaperPreviewCubit(sl()))
    ..registerFactory<PaperHistoryCubit>(() => PaperHistoryCubit(sl()))
    ..registerFactory<QpGeneratorCubit>(() => QpGeneratorCubit(sl(), sl(), sl()))
    ..registerFactory<PublicQpCubit>(() => PublicQpCubit(sl(), sl()));
}
