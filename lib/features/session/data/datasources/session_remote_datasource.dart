import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/endpoints.dart';
import '../../domain/entities/study_enums.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/study_taxonomy.dart';
import '../../domain/entities/user_answer.dart';
import '../models/question_model.dart';

/// Outcome of a single question-batch request. Mirrors the statuses the React
/// `useQuestionPolling` hook reacts to: a ready batch, the server still
/// AI-generating (poll again), or a failed generation (retry a few times).
enum QuestionBatchStatus { ready, generating, failed }

class QuestionBatchResult {
  const QuestionBatchResult(this.status, this.questions);
  const QuestionBatchResult.generating() : this(QuestionBatchStatus.generating, const []);
  const QuestionBatchResult.failed() : this(QuestionBatchStatus.failed, const []);

  final QuestionBatchStatus status;
  final List<QuestionModel> questions;
}

abstract class SessionRemoteDataSource {
  Future<List<ClassOption>> getClasses();
  Future<List<SubjectOption>> getSubjects(String classId);
  Future<List<ChapterOption>> getChapters(String classId, String subjectId);
  Future<QuestionBatchResult> fetchQuestionBatch({
    required String chapterId,
    required String type,
    required String difficulty,
    required String sessionId,
  });
  Future<void> submitAnswers(List<Map<String, dynamic>> answers);
  Future<String> createSession(Map<String, dynamic> session);
  Future<void> submitNps(Map<String, dynamic> data);

  /// Past sessions for a user (mirrors React `fetchSessionsByUserId`).
  Future<List<StudySession>> fetchSessionsByUserId(String userId);

  /// Recorded answers for one session (mirrors React `fetchUserAnswersBySession`).
  Future<List<UserAnswer>> fetchUserAnswersBySession(String sessionId);

  /// Closes a session with its final score (mirrors React `endSession`).
  Future<void> endSession(String sessionId, int score, int totalQuestions);

  /// Emoji reaction after a session.
  Future<void> submitReaction(Map<String, dynamic> data);

  /// Whether the user should be shown the NPS survey.
  Future<bool> checkNpsEligibility(String userId);

  /// Completes today's daily challenge; returns the (envelope-unwrapped) result.
  Future<Map<String, dynamic>> completeDailyChallenge(
      String userId, List<Map<String, dynamic>> answers);

  /// Spends a streak freeze.
  Future<void> useStreakFreeze(String userId);

  /// Share-card data for a completed session (null when none).
  Future<Map<String, dynamic>?> getShareCard(String sessionId);

  /// Newly-earned badge ids after a session.
  Future<List<dynamic>> checkNewBadges(String userId, Map<String, dynamic> sessionData);
}

class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  SessionRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  List<dynamic> _list(Response res, [List<String> keys = const ['data']]) {
    final found = _digList(res.data, [...keys, 'questions', 'results', 'items']);
    if (found != null) return found;
    throw ServerException('Unexpected list response', statusCode: res.statusCode);
  }

  /// Finds the first list in a possibly envelope-wrapped response. The batch
  /// endpoint double-wraps as `{ data: { data: [...] } }`, so descend through
  /// nested envelope maps (bounded depth) until a list turns up.
  static List<dynamic>? _digList(
    dynamic node,
    List<String> keys, [
    int depth = 0,
  ]) {
    if (node is List) return node;
    if (node is Map && depth < 5) {
      for (final k in keys) {
        if (node[k] is List) return node[k] as List;
      }
      for (final k in keys) {
        final child = node[k];
        if (child is Map) {
          final nested = _digList(child, keys, depth + 1);
          if (nested != null) return nested;
        }
      }
    }
    return null;
  }

  @override
  Future<List<ClassOption>> getClasses() async {
    final res = await _dio.get(Endpoints.classes);
    return _list(res)
        .map((e) => ClassOption(
              id: (e['_id'] ?? e['id']).toString(),
              name: (e['name'] ?? e['className'] ?? '').toString(),
            ))
        .toList();
  }

  @override
  Future<List<SubjectOption>> getSubjects(String classId) async {
    final res = await _dio.get(Endpoints.subjectsByClass(classId));
    return _list(res)
        .map((e) => SubjectOption(
              id: (e['_id'] ?? e['id']).toString(),
              name: (e['name'] ?? e['subjectName'] ?? '').toString(),
              classId: classId,
            ))
        .toList();
  }

  @override
  Future<List<ChapterOption>> getChapters(
    String classId,
    String subjectId,
  ) async {
    final res = await _dio.get(Endpoints.chapters(classId, subjectId));
    return _list(res)
        .map((e) => ChapterOption(
              id: (e['_id'] ?? e['id']).toString(),
              name: (e['name'] ?? e['chapterName'] ?? '').toString(),
              number: (e['number'] ?? e['chapterNumber']) is num
                  ? (e['number'] ?? e['chapterNumber']).toInt()
                  : null,
              subjectId: subjectId,
            ))
        .toList();
  }

  @override
  Future<QuestionBatchResult> fetchQuestionBatch({
    required String chapterId,
    required String type,
    required String difficulty,
    required String sessionId,
  }) async {
    final res = await _dio.get(
      Endpoints.questionsBatch(
        chapterId: chapterId,
        type: type,
        difficulty: difficulty,
        sessionId: sessionId,
      ),
    );

    // The server signals an in-flight AI generation with a `status` field
    // (possibly inside the `{ data: ... }` envelope) instead of a question list.
    final status = _statusOf(res.data);
    if (status == 'generating') return const QuestionBatchResult.generating();
    if (status == 'failed') return const QuestionBatchResult.failed();

    final list = _digList(res.data, const ['data', 'questions', 'results', 'items']);
    final questions = (list ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((m) => QuestionModel.fromJson({
              ...m,
              // The API sends the format under `questionType`; the model reads
              // `type`. Bridge it so fill-in-the-blank isn't misread as mcq.
              if (m['type'] == null && m['questionType'] != null)
                'type': m['questionType'],
            }))
        .toList();

    // An empty list with a 2xx (often "Questions batch fetched successfully")
    // means the bank is still being generated — treat it as `generating` so the
    // repository keeps polling, mirroring the frontend's empty-success branch.
    if (questions.isEmpty) return const QuestionBatchResult.generating();
    return QuestionBatchResult(QuestionBatchStatus.ready, questions);
  }

  /// Reads a `status` string from the body or its `data` envelope, if present.
  static String? _statusOf(dynamic body) {
    if (body is Map) {
      final s = body['status'];
      if (s is String) return s;
      final inner = body['data'];
      if (inner is Map && inner['status'] is String) {
        return inner['status'] as String;
      }
    }
    return null;
  }

  @override
  Future<void> submitAnswers(List<Map<String, dynamic>> answers) =>
      _dio.post(Endpoints.userAnswers, data: {'answers': answers});

  @override
  Future<void> submitNps(Map<String, dynamic> data) =>
      _dio.post(Endpoints.sessionFeedbackNps, data: data);

  @override
  Future<String> createSession(Map<String, dynamic> session) async {
    final res = await _dio.post(Endpoints.sessions, data: session);
    final body = res.data;
    // Backend wraps the created session in `{ success, data: {...} }`, but some
    // responses return the object directly — handle both shapes.
    final inner = (body is Map && body['data'] is Map) ? body['data'] as Map : body;
    if (inner is Map) {
      return (inner['_id'] ?? inner['id'] ?? inner['sessionId'] ?? '').toString();
    }
    return '';
  }

  /// Unwraps `{ success, data: {...} }`, returning the inner map (or the body).
  Map<String, dynamic>? _unwrap(Response res) {
    final body = res.data;
    if (body is Map) {
      final inner = body['data'] is Map ? body['data'] as Map : body;
      return Map<String, dynamic>.from(inner);
    }
    return null;
  }

  @override
  Future<List<StudySession>> fetchSessionsByUserId(String userId) async {
    final res = await _dio.get(Endpoints.sessionsByUser(userId));
    return _list(res)
        .whereType<Map<String, dynamic>>()
        .map(_sessionFromServer)
        .toList();
  }

  @override
  Future<List<UserAnswer>> fetchUserAnswersBySession(String sessionId) async {
    final res = await _dio.get(Endpoints.userAnswersBySession(sessionId));
    return _list(res)
        .whereType<Map<String, dynamic>>()
        .map(_answerFromServer)
        .toList();
  }

  /// Maps a server session document to a [StudySession]. The history list does
  /// not carry per-question answers; those load on demand via
  /// [fetchUserAnswersBySession]. `score`/`totalquestions` drive the badge.
  static StudySession _sessionFromServer(Map<String, dynamic> json) {
    return StudySession(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      className: (json['class'] ?? json['className'] ?? '').toString(),
      subjectName: (json['subject'] ?? json['subjectName'] ?? '').toString(),
      chapterName: (json['chapter'] ?? json['chapterName'] ?? '').toString(),
      questionType:
          QuestionType.fromApi((json['questionType'] ?? json['type'])?.toString()),
      difficulty: Difficulty.fromApi(json['difficulty']?.toString()),
      startedAtMillis: _parseDate(
          json['createdAt'] ?? json['timestamp'] ?? json['startedAt']),
      totalQuestions:
          _toInt(json['totalquestions'] ?? json['totalQuestions']),
      score: _toInt(json['score']),
      completed: true,
    );
  }

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  /// Maps a server user-answer document to a [UserAnswer]. The backend stores
  /// the chosen value under `selectedAnswer`/`selectedOption`, and embeds the
  /// question document under `questionId` (populated) — or sometimes `question`.
  /// The React `UserAnswers` view reads `qa.questionId?.x || qa.question?.x`, so
  /// pull the question text/options/correct answer/explanation from whichever
  /// of the two is an object, to drive the review transcript.
  static UserAnswer _answerFromServer(Map<String, dynamic> json) {
    final rawQuestionId = json['questionId'];
    // `questionId` is either a populated question object or a plain id string;
    // `question` is the legacy embed key. Use whichever is a Map for details.
    final question = rawQuestionId is Map
        ? rawQuestionId
        : (json['question'] is Map ? json['question'] as Map : null);

    final questionIdStr = (rawQuestionId is Map
            ? (rawQuestionId['_id'] ?? rawQuestionId['id'])
            : rawQuestionId) ??
        (question != null ? (question['_id'] ?? question['id']) : null) ??
        '';

    return UserAnswer(
      questionId: questionIdStr.toString(),
      sessionId: (json['sessionId'] ?? '').toString(),
      answer: (json['selectedAnswer'] ??
              json['selectedOption'] ??
              json['answer'] ??
              '')
          .toString(),
      isCorrect: json['isCorrect'] == true,
      answeredAtMillis: _parseDate(json['createdAt'] ?? json['answeredAt']),
      synced: true,
      questionText: question == null
          ? null
          : (question['questionText'] ?? question['question'])?.toString(),
      options: question == null
          ? const []
          : (question['options'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      correctAnswer: question == null
          ? null
          : (question['correctAnswer'] ?? question['answer'])?.toString(),
      explanation: question?['explanation']?.toString(),
      timeSpentSeconds: (json['timeSpent'] as num?)?.toInt(),
    );
  }

  /// Accepts an epoch (ms) number or an ISO-8601 string; 0 when unparseable.
  static int _parseDate(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  @override
  Future<void> endSession(String sessionId, int score, int totalQuestions) =>
      _dio.patch(Endpoints.sessionEnd(sessionId),
          // React sends the lowercase key `totalquestions`.
          data: {'score': score, 'totalquestions': totalQuestions});

  @override
  Future<void> submitReaction(Map<String, dynamic> data) =>
      _dio.post(Endpoints.sessionFeedbackReaction, data: data);

  @override
  Future<bool> checkNpsEligibility(String userId) async {
    final res = await _dio.get(Endpoints.npsEligibility(userId));
    final data = _unwrap(res);
    return data?['shouldShowNps'] == true;
  }

  @override
  Future<Map<String, dynamic>> completeDailyChallenge(
      String userId, List<Map<String, dynamic>> answers) async {
    final res = await _dio.post(Endpoints.dailyChallengeComplete(userId),
        data: {'answers': answers});
    return _unwrap(res) ?? const {};
  }

  @override
  Future<void> useStreakFreeze(String userId) =>
      _dio.post(Endpoints.streakUseFreeze(userId));

  @override
  Future<Map<String, dynamic>?> getShareCard(String sessionId) async {
    final res = await _dio.get(Endpoints.sessionShare(sessionId));
    return _unwrap(res);
  }

  @override
  Future<List<dynamic>> checkNewBadges(
      String userId, Map<String, dynamic> sessionData) async {
    final res = await _dio.post(Endpoints.badgesCheck,
        data: {'userId': userId, ...sessionData});
    final data = res.data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return const [];
  }
}
