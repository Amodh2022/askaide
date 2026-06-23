import 'package:equatable/equatable.dart';

/// A recorded answer. Collected in batches and submitted to `/user-answers`;
/// queued locally (with [synced] = false) when offline.
class UserAnswer extends Equatable {
  const UserAnswer({
    required this.questionId,
    required this.sessionId,
    required this.answer,
    required this.isCorrect,
    required this.answeredAtMillis,
    this.synced = false,
  });

  final String questionId;
  final String sessionId;
  final String answer;
  final bool isCorrect;
  final int answeredAtMillis;
  final bool synced;

  UserAnswer copyWith({bool? synced}) => UserAnswer(
        questionId: questionId,
        sessionId: sessionId,
        answer: answer,
        isCorrect: isCorrect,
        answeredAtMillis: answeredAtMillis,
        synced: synced ?? this.synced,
      );

  /// Local (Hive) serialization — keeps queue-only fields (`answeredAt`,
  /// `synced`) used by the offline answer queue.
  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'sessionId': sessionId,
        'answer': answer,
        'isCorrect': isCorrect,
        'answeredAt': answeredAtMillis,
        'synced': synced,
      };

  /// Wire payload for `POST /user-answers/batch`. The backend records the
  /// chosen answer under `selectedAnswer`/`selectedOption` (the React client
  /// sends both) — not `answer` — so emit those keys and drop the local-only
  /// queue fields (`answeredAt`, `synced`).
  Map<String, dynamic> toWireJson() => {
        'questionId': questionId,
        'sessionId': sessionId,
        'selectedAnswer': answer,
        'selectedOption': answer,
        'isCorrect': isCorrect,
      };

  factory UserAnswer.fromJson(Map<String, dynamic> json) => UserAnswer(
        questionId: json['questionId']?.toString() ?? '',
        sessionId: json['sessionId']?.toString() ?? '',
        answer: json['answer']?.toString() ?? '',
        isCorrect: json['isCorrect'] == true,
        answeredAtMillis: (json['answeredAt'] as num?)?.toInt() ?? 0,
        synced: json['synced'] == true,
      );

  @override
  List<Object?> get props =>
      [questionId, sessionId, answer, isCorrect, answeredAtMillis, synced];
}
