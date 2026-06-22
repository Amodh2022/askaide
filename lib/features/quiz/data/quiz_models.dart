import 'package:equatable/equatable.dart';

import '../../../core/network/api_helpers.dart';

/// A quiz as shown in the student's available/assigned list.
class QuizSummary extends Equatable {
  const QuizSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.totalQuestions,
    required this.totalMarks,
    required this.status,
    this.deadline,
  });

  final String id;
  final String title;
  final String description;
  final int totalQuestions;
  final int totalMarks;
  final String status; // available | in_progress | completed | expired
  final String? deadline;

  factory QuizSummary.fromJson(Map<dynamic, dynamic> j) => QuizSummary(
        id: j.str(['_id', 'id', 'quizId']),
        title: j.str(['title'], 'Untitled quiz'),
        description: j.str(['description']),
        totalQuestions: j.intval(['totalQuestions', 'questionCount']),
        totalMarks: j.intval(['totalMarks']),
        status: j.str(['status'], 'available'),
        deadline: j['deadline']?.toString(),
      );

  @override
  List<Object?> get props =>
      [id, title, description, totalQuestions, totalMarks, status, deadline];
}

/// A question presented during an attempt (no correct answer revealed).
class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.marks,
  });

  final String id; // quizQuestionId
  final String text;
  final List<String> options;
  final int marks;

  factory QuizQuestion.fromJson(Map<dynamic, dynamic> j) => QuizQuestion(
        id: j.str(['_id', 'quizQuestionId', 'id']),
        text: j.str(['questionText', 'text', 'question']),
        options: j.listAt(['options']).map((e) => e.toString()).toList(),
        marks: j.intval(['marks'], 1),
      );

  @override
  List<Object?> get props => [id, text, options, marks];
}

/// A started attempt with its question set.
class QuizAttempt extends Equatable {
  const QuizAttempt({
    required this.attemptId,
    required this.quizId,
    required this.title,
    required this.questions,
    this.timeLimitMinutes,
    this.startedAt,
  });

  final String attemptId;
  final String quizId;
  final String title;
  final List<QuizQuestion> questions;

  /// Quiz time limit in minutes (`quiz.settings.timeLimit`); null = untimed.
  final int? timeLimitMinutes;

  /// When the attempt was started — the countdown anchor (`attempt.startedAt`).
  final DateTime? startedAt;

  /// The wall-clock instant the timer hits zero, or null when untimed.
  DateTime? get deadline => (timeLimitMinutes != null && startedAt != null)
      ? startedAt!.add(Duration(minutes: timeLimitMinutes!))
      : null;

  factory QuizAttempt.fromJson(Map<dynamic, dynamic> j) {
    final quiz = j['quiz'] is Map ? j['quiz'] as Map : const <dynamic, dynamic>{};
    final attempt = j['attempt'] is Map ? j['attempt'] as Map : const <dynamic, dynamic>{};
    final settings =
        quiz['settings'] is Map ? quiz['settings'] as Map : const <dynamic, dynamic>{};
    final tlRaw = settings['timeLimit'] ?? quiz['timeLimit'] ?? j['timeLimit'];
    final timeLimit = tlRaw is num ? tlRaw.toInt() : int.tryParse('${tlRaw ?? ''}');
    final startedRaw = (attempt['startedAt'] ?? j['startedAt'])?.toString();
    return QuizAttempt(
      attemptId: j.str(['_id', 'attemptId', 'id']),
      quizId: j.str(['quizId']),
      title: j.str(['title', 'quizTitle'], 'Quiz'),
      questions:
          j.listAt(['questions']).whereType<Map>().map(QuizQuestion.fromJson).toList(),
      timeLimitMinutes: (timeLimit != null && timeLimit > 0) ? timeLimit : null,
      startedAt: startedRaw != null ? DateTime.tryParse(startedRaw) : null,
    );
  }

  @override
  List<Object?> get props =>
      [attemptId, quizId, title, questions, timeLimitMinutes, startedAt];
}

/// A reviewed question in the result view.
class QuizReviewQuestion extends Equatable {
  const QuizReviewQuestion({
    required this.text,
    required this.options,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.explanation,
    required this.marks,
  });

  final String text;
  final List<String> options;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String explanation;
  final int marks;

  factory QuizReviewQuestion.fromJson(Map<dynamic, dynamic> j) => QuizReviewQuestion(
        text: j.str(['questionText', 'text']),
        options: j.listAt(['options']).map((e) => e.toString()).toList(),
        userAnswer: j.str(['userAnswer', 'selectedAnswer']),
        correctAnswer: j.str(['correctAnswer']),
        isCorrect: j.boolean(['isCorrect']),
        explanation: j.str(['explanation']),
        marks: j.intval(['marks'], 1),
      );

  @override
  List<Object?> get props =>
      [text, options, userAnswer, correctAnswer, isCorrect, explanation, marks];
}

/// The graded result of an attempt.
class QuizResult extends Equatable {
  const QuizResult({
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.passStatus,
    required this.questions,
  });

  final int score;
  final int totalMarks;
  final double percentage;
  final String passStatus;
  final List<QuizReviewQuestion> questions;

  factory QuizResult.fromJson(Map<dynamic, dynamic> j) => QuizResult(
        score: j.intval(['score']),
        totalMarks: j.intval(['totalMarks']),
        percentage: j.dbl(['percentage']),
        passStatus: j.str(['passStatus'], ''),
        questions: j
            .listAt(['questions'])
            .whereType<Map>()
            .map(QuizReviewQuestion.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [score, totalMarks, percentage, passStatus, questions];
}

/// A row in the student's quiz attempt history.
class QuizHistoryItem extends Equatable {
  const QuizHistoryItem({
    required this.attemptId,
    required this.quizTitle,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.timeSpent,
    required this.passingPercentage,
    this.submittedAt,
  });

  final String attemptId;
  final String quizTitle;
  final int score;
  final int totalMarks;
  final double percentage;
  final int timeSpent; // seconds
  final double passingPercentage;
  final String? submittedAt;

  bool get isPassed => percentage >= (passingPercentage > 0 ? passingPercentage : 50);

  factory QuizHistoryItem.fromJson(Map<dynamic, dynamic> j) => QuizHistoryItem(
        attemptId: j.str(['_id', 'attemptId', 'id']),
        quizTitle: j.str(['quizTitle', 'title'], 'Quiz'),
        score: j.intval(['score']),
        totalMarks: j.intval(['totalMarks']),
        percentage: j.dbl(['percentage']),
        timeSpent: j.intval(['timeSpent']),
        passingPercentage: j.dbl(['passingPercentage']),
        submittedAt: (j['submittedAt'] ?? j['completedAt'])?.toString(),
      );

  @override
  List<Object?> get props =>
      [attemptId, quizTitle, score, totalMarks, percentage, timeSpent, passingPercentage, submittedAt];
}

// ---- Teacher quiz management ----------------------------------------------

/// A quiz row in the teacher's quiz list.
class TeacherQuiz extends Equatable {
  const TeacherQuiz({
    required this.id,
    required this.title,
    required this.status,
    required this.questionCount,
    this.createdAt,
  });
  final String id;
  final String title;
  final String status; // draft | published | closed
  final int questionCount;
  final String? createdAt;

  factory TeacherQuiz.fromJson(Map<dynamic, dynamic> j) => TeacherQuiz(
        id: j.str(['_id', 'id']),
        title: j.str(['title'], 'Untitled quiz'),
        status: j.str(['status'], 'draft'),
        questionCount: j.intval(['questionCount', 'totalQuestions']),
        createdAt: j['createdAt']?.toString(),
      );

  @override
  List<Object?> get props => [id, title, status, questionCount, createdAt];
}

/// A question already attached to a quiz, as shown in the teacher's manager.
/// `id` is the quizQuestion `_id` used for reorder/remove operations.
class QuizManagedQuestion extends Equatable {
  const QuizManagedQuestion({
    required this.id,
    required this.text,
    required this.marks,
    required this.order,
  });
  final String id;
  final String text;
  final int marks;
  final int order;

  factory QuizManagedQuestion.fromJson(Map<dynamic, dynamic> j) {
    // Content lives on the populated `questionId` ref, or `customQuestion`.
    final custom = j['customQuestion'] is Map ? j['customQuestion'] as Map : const {};
    final ref = j['questionId'] is Map ? j['questionId'] as Map : const {};
    final src = custom.isNotEmpty ? custom : ref;
    return QuizManagedQuestion(
      id: j.str(['_id', 'id']),
      text: src.str(['questionText', 'text']),
      marks: j.intval(['marks'], 1),
      order: j.intval(['order']),
    );
  }

  @override
  List<Object?> get props => [id, text, marks, order];
}

/// A question from the question bank (teacher building a quiz).
class BankQuestion extends Equatable {
  const BankQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.difficulty,
    required this.type,
  });
  final String id;
  final String text;
  final List<String> options;
  final String difficulty;
  final String type;

  factory BankQuestion.fromJson(Map<dynamic, dynamic> j) => BankQuestion(
        id: j.str(['_id', 'id']),
        text: j.str(['questionText', 'text']),
        options: j.listAt(['options']).map((e) => e.toString()).toList(),
        difficulty: j.str(['difficulty'], 'Medium'),
        type: j.str(['type', 'questionType'], 'mcq'),
      );

  @override
  List<Object?> get props => [id, text, options, difficulty, type];
}

/// Per-question analysis row from the analytics response (`questionAnalysis[]`).
class QuizQuestionStat extends Equatable {
  const QuizQuestionStat({
    required this.questionId,
    required this.order,
    required this.questionText,
    required this.correctPercentage,
    required this.totalAttempts,
    required this.avgTimeSpent,
    required this.marks,
  });

  final String questionId;
  final int order;
  final String questionText;
  final double correctPercentage;
  final int totalAttempts;
  final int avgTimeSpent; // seconds
  final int marks;

  factory QuizQuestionStat.fromJson(Map<dynamic, dynamic> j) => QuizQuestionStat(
        questionId: j.str(['questionId', '_id', 'id']),
        order: j.intval(['order']),
        questionText: j.str(['questionText', 'text']),
        correctPercentage: j.dbl(['correctPercentage', 'correctRate']),
        totalAttempts: j.intval(['totalAttempts', 'attempts']),
        avgTimeSpent: j.intval(['avgTimeSpent']),
        marks: j.intval(['marks'], 1),
      );

  @override
  List<Object?> get props =>
      [questionId, order, questionText, correctPercentage, totalAttempts, avgTimeSpent, marks];
}

/// A student entry in the top-performers / struggling lists.
class QuizStudentStat extends Equatable {
  const QuizStudentStat({
    required this.studentId,
    required this.name,
    required this.score,
    required this.percentage,
    required this.timeSpent,
  });

  final String studentId;
  final String name;
  final int score;
  final double percentage;
  final int timeSpent; // seconds

  factory QuizStudentStat.fromJson(Map<dynamic, dynamic> j) {
    final student = j['student'] is Map ? j['student'] as Map : const <dynamic, dynamic>{};
    return QuizStudentStat(
      studentId: student.str(['_id', 'id'], j.str(['studentId', '_id'])),
      name: student.str(['name'], j.str(['name'], 'Unknown')),
      score: j.intval(['score']),
      percentage: j.dbl(['percentage']),
      timeSpent: j.intval(['timeSpent']),
    );
  }

  @override
  List<Object?> get props => [studentId, name, score, percentage, timeSpent];
}

/// Quiz analytics overview + per-question analysis + student lists.
class QuizAnalyticsData extends Equatable {
  const QuizAnalyticsData({
    this.totalAttempts = 0,
    this.avgScore = 0,
    this.passRate = 0,
    this.totalStudentsAssigned = 0,
    this.completedAttempts = 0,
    this.inProgressAttempts = 0,
    this.avgTimeSpent = 0,
    this.totalMarks = 0,
    this.questionAnalysis = const [],
    this.topPerformers = const [],
    this.strugglingStudents = const [],
  });
  final int totalAttempts;
  final double avgScore;
  final double passRate;
  final int totalStudentsAssigned;
  final int completedAttempts;
  final int inProgressAttempts;
  final int avgTimeSpent; // seconds
  final int totalMarks;
  final List<QuizQuestionStat> questionAnalysis;
  final List<QuizStudentStat> topPerformers;
  final List<QuizStudentStat> strugglingStudents;

  factory QuizAnalyticsData.fromJson(Map<dynamic, dynamic> j) {
    final overview = j['overview'] is Map ? j['overview'] as Map : j;
    final quiz = j['quiz'] is Map ? j['quiz'] as Map : const <dynamic, dynamic>{};
    return QuizAnalyticsData(
      totalAttempts: overview.intval(['totalAttempts', 'attempts', 'completedAttempts']),
      avgScore: overview.dbl(['avgScore', 'averageScore']),
      passRate: overview.dbl(['passRate', 'passPercentage']),
      totalStudentsAssigned: overview.intval(['totalStudentsAssigned']),
      completedAttempts: overview.intval(['completedAttempts', 'totalAttempts']),
      inProgressAttempts: overview.intval(['inProgressAttempts']),
      avgTimeSpent: overview.intval(['avgTimeSpent']),
      totalMarks: quiz.intval(['totalMarks']),
      questionAnalysis: j
          .listAt(['questionAnalysis'])
          .whereType<Map>()
          .map(QuizQuestionStat.fromJson)
          .toList(),
      topPerformers:
          j.listAt(['topPerformers']).whereType<Map>().map(QuizStudentStat.fromJson).toList(),
      strugglingStudents: j
          .listAt(['strugglingStudents'])
          .whereType<Map>()
          .map(QuizStudentStat.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        totalAttempts,
        avgScore,
        passRate,
        totalStudentsAssigned,
        completedAttempts,
        inProgressAttempts,
        avgTimeSpent,
        totalMarks,
        questionAnalysis,
        topPerformers,
        strugglingStudents,
      ];
}
