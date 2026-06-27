import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_helpers.dart';
import '../../../../core/network/endpoints.dart';
import '../../domain/entities/ai_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

/// Talks to the AI assistant: single-shot ask, SSE streaming, the
/// conversation CRUD endpoints, and the teacher content-generation tool.
class AiAssistantRepositoryImpl implements AiAssistantRepository {
  AiAssistantRepositoryImpl(this._dio);
  final Dio _dio;

  /// Single-shot answer via `POST /ai-assistant`.
  @override
  Future<Either<Failure, String>> ask(String prompt) => guardEither(() async {
        final res = await _dio.post(
          Endpoints.aiProcess,
          data: {'prompt': prompt},
          options: Options(
            receiveTimeout: const Duration(seconds: 600),
            sendTimeout: const Duration(seconds: 600),
          ),
        );
        final d = res.dataMap();
        final content = d.str(['content', 'message', 'answer', 'text']);
        if (content.isNotEmpty) return content;
        final clarifications = d.listAt(['clarificationQuestions']);
        if (clarifications.isNotEmpty && clarifications.first is Map) {
          return (clarifications.first as Map)['question']?.toString() ??
              'Could you give me more detail?';
        }
        return 'I generated a response, but it was empty. Try rephrasing your question.';
      });

  /// Streams an answer via `POST /ai-assistant/stream` (SSE). Yields text chunks
  /// as they arrive. Falls back to a single error chunk on failure.
  @override
  Stream<String> stream(String prompt) async* {
    try {
      final res = await _dio.post<ResponseBody>(
        '/ai-assistant/stream',
        data: {'prompt': prompt},
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 600),
          sendTimeout: const Duration(seconds: 600),
        ),
      );
      final lines = res.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
        final payload = trimmed.substring(5).trim();
        if (payload == '[DONE]') break;
        try {
          final evt = jsonDecode(payload);
          if (evt is Map) {
            final type = evt['type']?.toString();
            if (type == 'chunk' && evt['content'] != null) {
              yield evt['content'].toString();
            } else if (type == 'error') {
              yield '\n\n_(${evt['message'] ?? 'stream error'})_';
              break;
            } else if (type == 'done') {
              break;
            }
          }
        } catch (_) {
          // Non-JSON data line — emit as-is.
          yield payload;
        }
      }
    } catch (e) {
      yield "Sorry — I couldn't reach the assistant just now.";
    }
  }

  @override
  Future<Either<Failure, List<AiConversation>>> conversations() =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.aiConversations);
        return res
            .dataList(['conversations'])
            .whereType<Map>()
            .map(AiConversation.fromJson)
            .toList();
      });

  @override
  Future<Either<Failure, AiConversation>> createConversation(String title) =>
      guardEither(() async {
        final res = await _dio.post(Endpoints.aiConversations, data: {'title': title});
        final d = res.dataMap(['data', 'conversation']);
        return AiConversation.fromJson(d.isEmpty ? res.dataMap() : d);
      });

  @override
  Future<Either<Failure, List<AiMessage>>> messages(String conversationId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.aiConversationMessages(conversationId));
        return res.dataList(['messages']).whereType<Map>().map(AiMessage.fromJson).toList();
      });

  @override
  Future<Either<Failure, Unit>> addMessage(
          String conversationId, String role, String content) =>
      guardEither(() async {
        await _dio.post(Endpoints.aiConversationMessages(conversationId),
            data: {'role': role, 'content': content});
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteConversation(String conversationId) =>
      guardEither(() async {
        await _dio.delete(Endpoints.aiConversation(conversationId));
        return unit;
      });

  // ---- Teacher content generation -----------------------------------------

  static const _genTimeout = Duration(seconds: 600);

  /// Processes a teacher prompt (e.g. "Create a quiz on Newton's Laws"). The
  /// agent may return generated content or a set of clarification questions.
  /// Mirrors React `aiAssistantApi.processRequest`.
  @override
  Future<Either<Failure, AiGenerationResult>> processRequest({
    required String prompt,
    Map<String, dynamic>? responses,
    String? sessionId,
  }) =>
      guardEither(() async {
        final res = await _dio.post(
          Endpoints.aiProcess,
          data: {
            'prompt': prompt,
            if (responses != null) 'responses': responses,
            if (sessionId != null) 'sessionId': sessionId,
          },
          options: Options(receiveTimeout: _genTimeout, sendTimeout: _genTimeout),
        );
        return AiGenerationResult.fromJson(res.dataMap());
      });

  /// Continues a clarification session with answers. Mirrors React
  /// `aiAssistantApi.continueSession`.
  @override
  Future<Either<Failure, AiGenerationResult>> continueSession({
    required String sessionId,
    required Map<String, dynamic> responses,
  }) =>
      guardEither(() async {
        final res = await _dio.post(
          Endpoints.aiContinue,
          data: {'sessionId': sessionId, 'responses': responses},
          options: Options(receiveTimeout: _genTimeout, sendTimeout: _genTimeout),
        );
        return AiGenerationResult.fromJson(res.dataMap());
      });

  /// Classes the teacher can generate content for.
  @override
  Future<Either<Failure, List<dynamic>>> getTeacherClasses() =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.aiClasses);
        return res.dataList(['classes']);
      });

  /// Available AI tasks (quiz, paper, assignment, …).
  @override
  Future<Either<Failure, List<dynamic>>> getAvailableTasks() =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.aiTasks);
        return res.dataList(['tasks']);
      });

  /// AI service health check.
  @override
  Future<Either<Failure, bool>> checkHealth() => guardEither(() async {
        final res = await _dio.get(Endpoints.aiHealth);
        final d = res.dataMap();
        final status = d.str(['status']);
        return d.boolean(['healthy', 'ok'], status.toLowerCase() == 'ok' ||
            status.toLowerCase() == 'healthy');
      });

  /// Downloads a generated artefact as PDF bytes (mirrors React `downloadPDF`).
  @override
  Future<Either<Failure, List<int>>> downloadPdf(String generationId) =>
      guardEither(() async {
        final res = await _dio.get<List<int>>(
          Endpoints.aiExport(generationId),
          options: Options(responseType: ResponseType.bytes),
        );
        return res.data ?? const <int>[];
      });
}
