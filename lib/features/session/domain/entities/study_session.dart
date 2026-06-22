import 'package:equatable/equatable.dart';

import 'study_enums.dart';
import 'user_answer.dart';

/// A practice session persisted in local history. Stores enough metadata to
/// render a history row and to review answers (the UserAnswers state).
class StudySession extends Equatable {
  const StudySession({
    required this.id,
    required this.className,
    required this.subjectName,
    required this.chapterName,
    required this.questionType,
    required this.difficulty,
    required this.startedAtMillis,
    this.answers = const [],
    this.totalQuestions = 0,
    this.completed = false,
  });

  final String id;
  final String className;
  final String subjectName;
  final String chapterName;
  final QuestionType questionType;
  final Difficulty difficulty;
  final int startedAtMillis;
  final List<UserAnswer> answers;
  final int totalQuestions;
  final bool completed;

  int get correctCount => answers.where((a) => a.isCorrect).length;
  int get answeredCount => answers.length;
  double get accuracy =>
      answeredCount == 0 ? 0 : correctCount / answeredCount;

  String get title => '$subjectName · $chapterName';

  StudySession copyWith({
    List<UserAnswer>? answers,
    int? totalQuestions,
    bool? completed,
  }) {
    return StudySession(
      id: id,
      className: className,
      subjectName: subjectName,
      chapterName: chapterName,
      questionType: questionType,
      difficulty: difficulty,
      startedAtMillis: startedAtMillis,
      answers: answers ?? this.answers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'className': className,
        'subjectName': subjectName,
        'chapterName': chapterName,
        'questionType': questionType.apiValue,
        'difficulty': difficulty.apiValue,
        'startedAt': startedAtMillis,
        'totalQuestions': totalQuestions,
        'completed': completed,
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id']?.toString() ?? '',
        className: json['className']?.toString() ?? '',
        subjectName: json['subjectName']?.toString() ?? '',
        chapterName: json['chapterName']?.toString() ?? '',
        questionType: QuestionType.fromApi(json['questionType']?.toString()),
        difficulty: Difficulty.fromApi(json['difficulty']?.toString()),
        startedAtMillis: (json['startedAt'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        completed: json['completed'] == true,
        answers: (json['answers'] as List<dynamic>? ?? [])
            .map((e) => UserAnswer.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        id,
        className,
        subjectName,
        chapterName,
        questionType,
        difficulty,
        startedAtMillis,
        answers,
        totalQuestions,
        completed,
      ];
}
