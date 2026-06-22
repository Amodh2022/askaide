import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/network/api_helpers.dart';
import '../../core/network/endpoints.dart';

/// A conversation in the AI assistant history.
class AiConversation extends Equatable {
  const AiConversation({required this.id, required this.title});
  final String id;
  final String title;

  factory AiConversation.fromJson(Map<dynamic, dynamic> j) => AiConversation(
        id: j.str(['_id', 'id']),
        title: j.str(['title'], 'Conversation'),
      );

  @override
  List<Object?> get props => [id, title];
}

/// A single chat message.
class AiMessage extends Equatable {
  const AiMessage({required this.role, required this.content});
  final String role; // 'user' | 'assistant'
  final String content;

  bool get fromUser => role == 'user';

  factory AiMessage.fromJson(Map<dynamic, dynamic> j) => AiMessage(
        role: j.str(['role'], 'assistant'),
        content: j.str(['content', 'text', 'message']),
      );

  @override
  List<Object?> get props => [role, content];
}

/// Talks to the AI assistant: single-shot ask, SSE streaming, and the
/// conversation CRUD endpoints.
class AiAssistantRepository {
  AiAssistantRepository(this._dio);
  final Dio _dio;

  /// Single-shot answer via `POST /ai-assistant`.
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

  Future<Either<Failure, List<AiConversation>>> conversations() =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.aiConversations);
        return res
            .dataList(['conversations'])
            .whereType<Map>()
            .map(AiConversation.fromJson)
            .toList();
      });

  Future<Either<Failure, AiConversation>> createConversation(String title) =>
      guardEither(() async {
        final res = await _dio.post(Endpoints.aiConversations, data: {'title': title});
        final d = res.dataMap(['data', 'conversation']);
        return AiConversation.fromJson(d.isEmpty ? res.dataMap() : d);
      });

  Future<Either<Failure, List<AiMessage>>> messages(String conversationId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.aiConversationMessages(conversationId));
        return res.dataList(['messages']).whereType<Map>().map(AiMessage.fromJson).toList();
      });

  Future<Either<Failure, Unit>> addMessage(
          String conversationId, String role, String content) =>
      guardEither(() async {
        await _dio.post(Endpoints.aiConversationMessages(conversationId),
            data: {'role': role, 'content': content});
        return unit;
      });

  Future<Either<Failure, Unit>> deleteConversation(String conversationId) =>
      guardEither(() async {
        await _dio.delete(Endpoints.aiConversation(conversationId));
        return unit;
      });
}
