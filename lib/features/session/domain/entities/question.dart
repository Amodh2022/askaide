import 'package:equatable/equatable.dart';

import 'study_enums.dart';

/// A single practice question. MCQs carry [options]; fill-in-the-blank questions
/// leave it empty and match against [correctAnswer] (case-insensitive, trimmed).
class Question extends Equatable {
  const Question({
    required this.id,
    required this.type,
    required this.text,
    required this.correctAnswer,
    this.options = const [],
    this.explanation,
    this.difficulty = Difficulty.medium,
    this.chapterId,
  });

  final String id;
  final QuestionType type;
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final Difficulty difficulty;
  final String? chapterId;

  /// Grades a user's answer locally for instant feedback.
  bool isCorrect(String answer) {
    final a = answer.trim().toLowerCase();
    final c = correctAnswer.trim().toLowerCase();
    return a == c;
  }

  @override
  List<Object?> get props =>
      [id, type, text, options, correctAnswer, explanation, difficulty, chapterId];
}
