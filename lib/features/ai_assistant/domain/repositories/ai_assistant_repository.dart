import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_models.dart';

/// Talks to the AI assistant: single-shot ask, SSE streaming, the
/// conversation CRUD endpoints, and the teacher content-generation tool.
abstract class AiAssistantRepository {
  /// Single-shot answer via `POST /ai-assistant`.
  Future<Either<Failure, String>> ask(String prompt);

  /// Streams an answer via `POST /ai-assistant/stream` (SSE). Yields text chunks
  /// as they arrive. Falls back to a single error chunk on failure.
  Stream<String> stream(String prompt);

  Future<Either<Failure, List<AiConversation>>> conversations();

  Future<Either<Failure, AiConversation>> createConversation(String title);

  Future<Either<Failure, List<AiMessage>>> messages(String conversationId);

  Future<Either<Failure, Unit>> addMessage(
      String conversationId, String role, String content);

  Future<Either<Failure, Unit>> deleteConversation(String conversationId);

  // ---- Teacher content generation -----------------------------------------

  /// Processes a teacher prompt (e.g. "Create a quiz on Newton's Laws"). The
  /// agent may return generated content or a set of clarification questions.
  /// Mirrors React `aiAssistantApi.processRequest`.
  Future<Either<Failure, AiGenerationResult>> processRequest({
    required String prompt,
    Map<String, dynamic>? responses,
    String? sessionId,
  });

  /// Continues a clarification session with answers. Mirrors React
  /// `aiAssistantApi.continueSession`.
  Future<Either<Failure, AiGenerationResult>> continueSession({
    required String sessionId,
    required Map<String, dynamic> responses,
  });

  /// Classes the teacher can generate content for.
  Future<Either<Failure, List<dynamic>>> getTeacherClasses();

  /// Available AI tasks (quiz, paper, assignment, …).
  Future<Either<Failure, List<dynamic>>> getAvailableTasks();

  /// AI service health check.
  Future<Either<Failure, bool>> checkHealth();

  /// Downloads a generated artefact as PDF bytes (mirrors React `downloadPDF`).
  Future<Either<Failure, List<int>>> downloadPdf(String generationId);
}
