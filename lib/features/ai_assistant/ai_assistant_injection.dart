import 'package:get_it/get_it.dart';

import 'ai_assistant_repository.dart';

void registerAiAssistant(GetIt sl) {
  sl.registerLazySingleton<AiAssistantRepository>(() => AiAssistantRepository(sl()));
}
