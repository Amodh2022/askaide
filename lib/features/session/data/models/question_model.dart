import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/question.dart';
import '../../domain/entities/study_enums.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

/// DTO for a question coming from the batch endpoint (and the AI fallback).
/// Tolerant of several key spellings the backend has used historically.
@freezed
class QuestionModel with _$QuestionModel {
  const QuestionModel._();

  const factory QuestionModel({
    @JsonKey(name: '_id') String? id,
    String? questionText,
    String? question,
    String? type,
    List<String>? options,
    String? correctAnswer,
    String? answer,
    String? explanation,
    String? difficulty,
    String? chapterId,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);

  Question toEntity() => Question(
        id: id ?? UniqueKeyFallback.next(),
        type: QuestionType.fromApi(type),
        text: questionText ?? question ?? '',
        options: options ?? const [],
        correctAnswer: correctAnswer ?? answer ?? '',
        explanation: explanation,
        difficulty: Difficulty.fromApi(difficulty),
        chapterId: chapterId,
      );
}

/// Deterministic-enough fallback id when the API omits one. Avoids
/// `Math.random`/`DateTime.now` so generated questions still get stable keys
/// within a render pass.
class UniqueKeyFallback {
  UniqueKeyFallback._();
  static int _counter = 0;
  static String next() => 'q_local_${_counter++}';
}
