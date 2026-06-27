import 'package:equatable/equatable.dart';

import '../../../../core/network/api_helpers.dart';

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

/// A clarification question the AI agent asks before generating content.
class AiClarification extends Equatable {
  const AiClarification({required this.id, required this.question, this.options = const []});
  final String id;
  final String question;
  final List<String> options;

  factory AiClarification.fromJson(Map<dynamic, dynamic> j) => AiClarification(
        id: j.str(['id', 'key', '_id']),
        question: j.str(['question', 'text', 'label']),
        options: j.listAt(['options', 'choices']).map((e) => e.toString()).toList(),
      );

  @override
  List<Object?> get props => [id, question, options];
}

/// Result of a teacher content-generation request. Either the agent needs
/// clarification (carry [sessionId] back via `continueSession`) or it returns
/// generated [content] addressable by [generationId] (for PDF export).
class AiGenerationResult extends Equatable {
  const AiGenerationResult({
    this.needsClarification = false,
    this.clarifications = const [],
    this.message = '',
    this.content,
    this.sessionId,
    this.generationId,
  });

  final bool needsClarification;
  final List<AiClarification> clarifications;
  final String message;
  final Map<String, dynamic>? content;
  final String? sessionId;
  final String? generationId;

  factory AiGenerationResult.fromJson(Map<dynamic, dynamic> j) {
    final clar = j.listAt(['clarificationQuestions', 'clarifications', 'questions'])
        .whereType<Map>()
        .map(AiClarification.fromJson)
        .toList();
    final rawContent = j['content'] ?? j['generation'] ?? j['result'];
    return AiGenerationResult(
      needsClarification:
          j.boolean(['needsClarification']) || clar.isNotEmpty,
      clarifications: clar,
      message: j.str(['message', 'answer', 'text']),
      content: rawContent is Map ? Map<String, dynamic>.from(rawContent) : null,
      sessionId: j.str(['sessionId']).isNotEmpty ? j.str(['sessionId']) : null,
      generationId: j.str(['generationId', '_id']).isNotEmpty
          ? j.str(['generationId', '_id'])
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [needsClarification, clarifications, message, content, sessionId, generationId];
}
