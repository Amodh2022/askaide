import 'package:get_it/get_it.dart';

import 'data/repositories/ai_assistant_repository_impl.dart';
import 'domain/repositories/ai_assistant_repository.dart';

void registerAiAssistant(GetIt sl) {
  // One implementation satisfies both role interfaces (ISP); register the
  // concrete once and expose each narrow contract pointing at that instance.
  sl
    ..registerLazySingleton<AiAssistantRepositoryImpl>(
        () => AiAssistantRepositoryImpl(sl()))
    ..registerLazySingleton<AiChatRepository>(
        () => sl<AiAssistantRepositoryImpl>())
    ..registerLazySingleton<AiTeacherToolsRepository>(
        () => sl<AiAssistantRepositoryImpl>());
}
