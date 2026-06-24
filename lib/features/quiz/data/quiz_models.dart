import 'package:equatable/equatable.dart';

import '../../../core/network/api_helpers.dart';

/// Shared pagination metadata returned by the quiz list endpoints.
class QuizPagination extends Equatable {
  const QuizPagination({
    this.page = 1,
    this.limit = 12,
    this.total = 0,
    this.pages = 1,
  });

  final int page;
  final int limit;
  final int total;
  final int pages;

  factory QuizPagination.fromJson(Map<dynamic, dynamic> j) {
    final page = j.intval(['page'], 1);
    final limit = j.intval(['limit'], 12);
    final total = j.intval(['total']);
    final pagesRaw = j.intval(['pages']);
    final pages = pagesRaw > 0
        ? pagesRaw
        : (total > 0 && limit > 0 ? (total / limit).ceil() : 1);
    return QuizPagination(
      page: page > 0 ? page : 1,
      limit: limit > 0 ? limit : 12,
      total: total,
      pages: pages > 0 ? pages : 1,
    );
  }

  QuizPagination copyWith({
    int? page,
    int? limit,
    int? total,
    int? pages,
  }) =>
      QuizPagination(
        page: page ?? this.page,
        limit: limit ?? this.limit,
        total: total ?? this.total,
        pages: pages ?? this.pages,
      );

  @override
  List<Object?> get props => [page, limit, total, pages];
}

/// A paginated list of quiz entities.
class QuizPage<T> {
  const QuizPage({required this.items, required this.pagination});

  final List<T> items;
  final QuizPagination pagination;
}

/// A quiz as shown in the student's available/assigned list.
///
/// The backend attaches an `attemptInfo` object that drives the row's state:
/// whether an attempt is in progress (resume), the best score so far, total
/// attempts, and whether another attempt is allowed. The deadline lives under
/// `settings.deadline`.
class QuizSummary extends Equatable {
  const QuizSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.totalQuestions,
    required this.totalMarks,
    required this.status,
    this.subjectName = 'Subject',
    this.className = 'Class',
    this.timeLimitMinutes,
    this.allowedAttempts = 1,
    this.deadline,
    this.inProgressAttemptId,
    this.lastAttemptId,
    this.bestScore,
    this.totalAttempts = 0,
    this.canAttempt = true,
    this.isExpired = false,
  });

  final String id;
  final String title;
  final String description;
  final int totalQuestions;
  final int totalMarks;
  final String status; // available | in_progress | completed | expired
  final String subjectName;
  final String className;

  /// Quiz time limit in minutes (`settings.timeLimit`); null = untimed.
  final int? timeLimitMinutes;

  /// Max attempts allowed (`settings.allowedAttempts`); defaults to 1.
  final int allowedAttempts;
  final String? deadline;

  /// Attempt id to resume, when one is in progress (null = none).
  final String? inProgressAttemptId;
  final String? lastAttemptId;
  final int? bestScore;
  final int totalAttempts;
  final bool canAttempt;
  final bool isExpired;

  bool get hasInProgress =>
      inProgressAttemptId != null && inProgressAttemptId!.isNotEmpty;

  /// The deadline parsed to a [DateTime], or null when absent/unparseable.
  DateTime? get deadlineDate =>
      deadline == null ? null : DateTime.tryParse(deadline!);

  factory QuizSummary.fromJson(Map<dynamic, dynamic> j) {
    final info = j['attemptInfo'] is Map ? j['attemptInfo'] as Map : const {};
    final settings = j['settings'] is Map ? j['settings'] as Map : const {};
    final subjectRef = j['subjectId'] is Map ? j['subjectId'] as Map : const {};
    final classRef = j['classId'] is Map ? j['classId'] as Map : const {};
    final inProgress = info['inProgressAttempt'];
    final inProgressId = inProgress is Map
        ? inProgress.str(['_id', 'id'])
        : (inProgress?.toString() ?? '');
    final hasInProgress = inProgressId.isNotEmpty;
    final bestScore =
        info['bestScore'] is num ? (info['bestScore'] as num).toInt() : null;
    final isExpired = j.boolean(['isExpired']);
    // Status precedence mirrors the frontend StudentQuizList.getStatus():
    // in-progress → completed (has a best score) → expired → available.
    final status = hasInProgress
        ? 'in_progress'
        : bestScore != null
            ? 'completed'
            : isExpired
                ? 'expired'
                : 'available';
    final tl = settings['timeLimit'] ?? j['timeLimit'];
    final timeLimit = tl is num ? tl.toInt() : int.tryParse('${tl ?? ''}');
    return QuizSummary(
      id: j.str(['_id', 'id', 'quizId']),
      title: j.str(['title'], 'Untitled quiz'),
      description: j.str(['description']),
      totalQuestions: j.intval(['totalQuestions', 'questionCount']),
      totalMarks: j.intval(['totalMarks']),
      status: status,
      subjectName: subjectRef.str(['name']).isNotEmpty
          ? subjectRef.str(['name'])
          : j.str(['subjectName'], 'Subject'),
      className: classRef.str(['name']).isNotEmpty
          ? classRef.str(['name'])
          : j.str(['className'], 'Class'),
      timeLimitMinutes: (timeLimit != null && timeLimit > 0) ? timeLimit : null,
      allowedAttempts: settings.intval(['allowedAttempts'], 1),
      deadline: (settings['deadline'] ?? j['deadline'])?.toString(),
      inProgressAttemptId: hasInProgress ? inProgressId : null,
      lastAttemptId: info.str(['lastAttemptId']).isNotEmpty
          ? info.str(['lastAttemptId'])
          : null,
      bestScore: bestScore,
      totalAttempts: info.intval(['totalAttempts']),
      canAttempt: info.boolean(['canAttempt'], true),
      isExpired: isExpired,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        totalQuestions,
        totalMarks,
        status,
        subjectName,
        className,
        timeLimitMinutes,
        allowedAttempts,
        deadline,
        inProgressAttemptId,
        lastAttemptId,
        bestScore,
        totalAttempts,
        canAttempt,
        isExpired,
      ];
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

  factory QuizQuestion.fromJson(Map<dynamic, dynamic> j) {
    // Custom (teacher-authored) questions nest their content under
    // `customQuestion` — fall back to it when the top-level fields are absent.
    final custom =
        j['customQuestion'] is Map ? j['customQuestion'] as Map : const {};
    var text = j.str(['questionText', 'text', 'question']);
    if (text.isEmpty) text = custom.str(['questionText', 'text']);
    var options = j.listAt(['options']).map((e) => e.toString()).toList();
    if (options.isEmpty) {
      options = custom.listAt(['options']).map((e) => e.toString()).toList();
    }
    return QuizQuestion(
      id: j.str(['_id', 'quizQuestionId', 'id']),
      text: text,
      options: options,
      marks: j.intval(['marks'], 1),
    );
  }

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
    this.savedAnswers = const {},
  });

  final String attemptId;
  final String quizId;
  final String title;
  final List<QuizQuestion> questions;

  /// Previously-saved answers keyed by quizQuestionId, used to restore state
  /// when resuming an in-progress attempt (`attempt.answers[].{questionId,answer}`).
  final Map<String, String> savedAnswers;

  /// Quiz time limit in minutes (`quiz.settings.timeLimit`); null = untimed.
  final int? timeLimitMinutes;

  /// When the attempt was started — the countdown anchor (`attempt.startedAt`).
  final DateTime? startedAt;

  /// The wall-clock instant the timer hits zero, or null when untimed.
  DateTime? get deadline => (timeLimitMinutes != null && startedAt != null)
      ? startedAt!.add(Duration(minutes: timeLimitMinutes!))
      : null;

  factory QuizAttempt.fromJson(Map<dynamic, dynamic> j) {
    final quiz =
        j['quiz'] is Map ? j['quiz'] as Map : const <dynamic, dynamic>{};
    final attempt =
        j['attempt'] is Map ? j['attempt'] as Map : const <dynamic, dynamic>{};
    final settings = quiz['settings'] is Map
        ? quiz['settings'] as Map
        : const <dynamic, dynamic>{};
    final tlRaw = settings['timeLimit'] ?? quiz['timeLimit'] ?? j['timeLimit'];
    final timeLimit =
        tlRaw is num ? tlRaw.toInt() : int.tryParse('${tlRaw ?? ''}');
    final startedRaw = (attempt['startedAt'] ?? j['startedAt'])?.toString();
    // Restore previously-saved answers when resuming.
    final saved = <String, String>{};
    final answers = attempt['answers'] is List
        ? attempt['answers'] as List
        : (j['answers'] is List ? j['answers'] as List : const []);
    for (final a in answers.whereType<Map>()) {
      final qid = a.str(['questionId', 'quizQuestionId', '_id']);
      final ans = a.str(['answer', 'selectedAnswer', 'selectedOption']);
      if (qid.isNotEmpty && ans.isNotEmpty) saved[qid] = ans;
    }
    return QuizAttempt(
      attemptId: (attempt['_id'] ?? j['_id'] ?? j['attemptId'] ?? j['id'] ?? '')
          .toString(),
      quizId: j.str(['quizId']).isNotEmpty
          ? j.str(['quizId'])
          : quiz.str(['_id', 'id']),
      title: j.str(['title', 'quizTitle']).isNotEmpty
          ? j.str(['title', 'quizTitle'])
          : quiz.str(['title'], 'Quiz'),
      questions: j
          .listAt(['questions'])
          .whereType<Map>()
          .map(QuizQuestion.fromJson)
          .toList(),
      timeLimitMinutes: (timeLimit != null && timeLimit > 0) ? timeLimit : null,
      startedAt: startedRaw != null ? DateTime.tryParse(startedRaw) : null,
      savedAnswers: saved,
    );
  }

  @override
  List<Object?> get props => [
        attemptId,
        quizId,
        title,
        questions,
        timeLimitMinutes,
        startedAt,
        savedAnswers
      ];
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
    required this.marksObtained,
  });

  final String text;
  final List<String> options;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String explanation;
  final int marks; // total marks for the question
  final int marksObtained; // marks the student scored

  factory QuizReviewQuestion.fromJson(Map<dynamic, dynamic> j) =>
      QuizReviewQuestion(
        text: j.str(['questionText', 'text']),
        options: j.listAt(['options']).map((e) => e.toString()).toList(),
        userAnswer: j.str(['selectedAnswer', 'userAnswer']),
        correctAnswer: j.str(['correctAnswer']),
        isCorrect: j.boolean(['isCorrect']),
        explanation: j.str(['explanation']),
        marks: j.intval(['marks'], 1),
        marksObtained: j.intval(['marksObtained']),
      );

  @override
  List<Object?> get props => [
        text,
        options,
        userAnswer,
        correctAnswer,
        isCorrect,
        explanation,
        marks,
        marksObtained
      ];
}

/// The graded result of an attempt.
///
/// The result endpoint returns `{ attempt: {...}, quiz: {...},
/// questionDetails: [...], showAnswers }` (after the `{ success, data }`
/// envelope is unwrapped). Score/percentage/pass live on `attempt`; the
/// reviewed questions live on `questionDetails` (NOT `questions`).
class QuizResult extends Equatable {
  const QuizResult({
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.passed,
    required this.correctCount,
    required this.timeSpent,
    required this.questions,
    this.quizId = '',
    this.quizTitle = 'Your Results',
    this.passingPercentage = 50,
    this.showAnswers = true,
    this.canRetry = false,
  });

  final int score;
  final int totalMarks;
  final double percentage;
  final bool passed;
  final int correctCount;
  final int timeSpent; // seconds
  final List<QuizReviewQuestion> questions;
  final String quizId;
  final String quizTitle;
  final double passingPercentage; // 0..100
  final bool showAnswers;
  final bool canRetry;

  /// Human-readable status used by the result screen.
  String get passStatus => passed ? 'PASS' : 'FAIL';

  factory QuizResult.fromJson(Map<dynamic, dynamic> j) {
    final attempt = j['attempt'] is Map ? j['attempt'] as Map : j;
    final quiz =
        j['quiz'] is Map ? j['quiz'] as Map : const <dynamic, dynamic>{};
    final quizSettings = quiz['settings'] is Map
        ? quiz['settings'] as Map
        : const <dynamic, dynamic>{};
    final review = j
        .listAt(['questionDetails', 'questions'])
        .whereType<Map>()
        .map(QuizReviewQuestion.fromJson)
        .toList();
    final score = attempt.intval(['score']);
    final totalMarks = attempt.intval(['totalMarks']) > 0
        ? attempt.intval(['totalMarks'])
        : quiz.intval(['totalMarks']);
    final pct = attempt.dbl(['percentage']);
    final passingPct = quizSettings.dbl(['passingPercentage']);
    return QuizResult(
      score: score,
      totalMarks: totalMarks,
      percentage:
          pct > 0 ? pct : (totalMarks > 0 ? (score / totalMarks) * 100 : 0),
      passed: attempt.boolean(['passed']),
      correctCount: attempt.intval(['totalCorrectAnswers']) > 0
          ? attempt.intval(['totalCorrectAnswers'])
          : review.where((q) => q.isCorrect).length,
      timeSpent: attempt.intval(['timeSpent']),
      questions: review,
      quizId: quiz.str(['_id', 'id']),
      quizTitle: quiz.str(['title'], 'Your Results'),
      passingPercentage: passingPct > 0 ? passingPct : 50,
      showAnswers: j['showAnswers'] != null ? j.boolean(['showAnswers']) : true,
      canRetry: attempt.boolean(['canRetry']),
    );
  }

  @override
  List<Object?> get props => [
        score,
        totalMarks,
        percentage,
        passed,
        correctCount,
        timeSpent,
        questions,
        quizId,
        quizTitle,
        passingPercentage,
        showAnswers,
        canRetry,
      ];
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

  bool get isPassed =>
      percentage >= (passingPercentage > 0 ? passingPercentage : 50);

  factory QuizHistoryItem.fromJson(Map<dynamic, dynamic> j) => QuizHistoryItem(
        attemptId: j.str(['_id', 'attemptId', 'id']),
        quizTitle: j.str(
          ['quizTitle', 'title'],
          j['quiz'] is Map ? (j['quiz'] as Map).str(['title'], 'Quiz') : 'Quiz',
        ),
        score: j.intval(['score']),
        totalMarks: j.intval(['totalMarks']),
        percentage: j.dbl(['percentage']),
        timeSpent: j.intval(['timeSpent']),
        passingPercentage: j.dbl(['passingPercentage']),
        submittedAt: (j['submittedAt'] ?? j['completedAt'])?.toString(),
      );

  @override
  List<Object?> get props => [
        attemptId,
        quizTitle,
        score,
        totalMarks,
        percentage,
        timeSpent,
        passingPercentage,
        submittedAt
      ];
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
    final custom =
        j['customQuestion'] is Map ? j['customQuestion'] as Map : const {};
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

  factory QuizQuestionStat.fromJson(Map<dynamic, dynamic> j) =>
      QuizQuestionStat(
        questionId: j.str(['questionId', '_id', 'id']),
        order: j.intval(['order']),
        questionText: j.str(['questionText', 'text']),
        correctPercentage: j.dbl(['correctPercentage', 'correctRate']),
        totalAttempts: j.intval(['totalAttempts', 'attempts']),
        avgTimeSpent: j.intval(['avgTimeSpent']),
        marks: j.intval(['marks'], 1),
      );

  @override
  List<Object?> get props => [
        questionId,
        order,
        questionText,
        correctPercentage,
        totalAttempts,
        avgTimeSpent,
        marks
      ];
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
    final student =
        j['student'] is Map ? j['student'] as Map : const <dynamic, dynamic>{};
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
    final quiz =
        j['quiz'] is Map ? j['quiz'] as Map : const <dynamic, dynamic>{};
    return QuizAnalyticsData(
      totalAttempts:
          overview.intval(['totalAttempts', 'attempts', 'completedAttempts']),
      avgScore: overview.dbl(['avgScore', 'averageScore']),
      passRate: overview.dbl(['passRate', 'passPercentage']),
      totalStudentsAssigned: overview.intval(['totalStudentsAssigned']),
      completedAttempts:
          overview.intval(['completedAttempts', 'totalAttempts']),
      inProgressAttempts: overview.intval(['inProgressAttempts']),
      avgTimeSpent: overview.intval(['avgTimeSpent']),
      totalMarks: quiz.intval(['totalMarks']),
      questionAnalysis: j
          .listAt(['questionAnalysis'])
          .whereType<Map>()
          .map(QuizQuestionStat.fromJson)
          .toList(),
      topPerformers: j
          .listAt(['topPerformers'])
          .whereType<Map>()
          .map(QuizStudentStat.fromJson)
          .toList(),
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
