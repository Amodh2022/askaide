import 'package:get_it/get_it.dart';

import 'data/repositories/ai_assistant_repository_impl.dart';
import 'domain/repositories/ai_assistant_repository.dart';

void registerAiAssistant(GetIt sl) {
  sl.registerLazySingleton<AiAssistantRepository>(
      () => AiAssistantRepositoryImpl(sl()));
}
