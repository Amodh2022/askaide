import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/api_helpers.dart';
import '../../../core/network/endpoints.dart';
import 'quiz_models.dart';

/// Remote data source + repository for the student quiz flow.
class QuizRepository {
  QuizRepository(this._dio);
  final Dio _dio;

  Future<Either<Failure, QuizPage<QuizSummary>>> available({
    int page = 1,
    int limit = 12,
    String? status,
    String? subjectId,
  }) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.quizStudentAvailable,
          queryParameters: {
            'page': page,
            'limit': limit,
            if (status != null && status.isNotEmpty) 'status': status,
            if (subjectId != null && subjectId.isNotEmpty)
              'subjectId': subjectId,
          },
        );
        final data = res.dataMap();
        final pagination = QuizPagination.fromJson(
          data['pagination'] is Map
              ? Map<dynamic, dynamic>.from(data['pagination'] as Map)
              : data,
        );
        return QuizPage<QuizSummary>(
          items: res
              .dataList(['quizzes'])
              .whereType<Map>()
              .map(QuizSummary.fromJson)
              .toList(),
          pagination: pagination,
        );
      });

  Future<Either<Failure, QuizPage<QuizHistoryItem>>> history({
    int page = 1,
    int limit = 10,
    String? subjectId,
  }) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.quizStudentHistory,
          queryParameters: {
            'page': page,
            'limit': limit,
            if (subjectId != null && subjectId.isNotEmpty)
              'subjectId': subjectId,
          },
        );
        final data = res.dataMap();
        final pagination = QuizPagination.fromJson(
          data['pagination'] is Map
              ? Map<dynamic, dynamic>.from(data['pagination'] as Map)
              : data,
        );
        return QuizPage<QuizHistoryItem>(
          items: res
              .dataList(['attempts'])
              .whereType<Map>()
              .map(QuizHistoryItem.fromJson)
              .toList(),
          pagination: pagination,
        );
      });

  Future<Either<Failure, QuizAttempt>> start(String quizId) =>
      guardEither(() async {
        final res = await _dio.post(Endpoints.quizStart(quizId));
        return QuizAttempt.fromJson(res.dataMap());
      });

  Future<Either<Failure, QuizAttempt>> getAttempt(String attemptId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.quizAttemptGet(attemptId));
        return QuizAttempt.fromJson(res.dataMap());
      });

  Future<Either<Failure, Unit>> answer(
    String attemptId, {
    required String quizQuestionId,
    required String selectedAnswer,
    required int timeSpent,
  }) =>
      guardEither(() async {
        await _dio.post(Endpoints.quizAttemptAnswer(attemptId), data: {
          'quizQuestionId': quizQuestionId,
          'selectedAnswer': selectedAnswer,
          'timeSpent': timeSpent,
        });
        return unit;
      });

  Future<Either<Failure, QuizResult>> submit(String attemptId) =>
      guardEither(() async {
        await _dio.post(Endpoints.quizAttemptSubmit(attemptId));
        final res = await _dio.get(Endpoints.quizAttemptResult(attemptId));
        return QuizResult.fromJson(res.dataMap());
      });

  Future<Either<Failure, QuizResult>> result(String attemptId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.quizAttemptResult(attemptId));
        return QuizResult.fromJson(res.dataMap());
      });
}

/// Teacher-side quiz management endpoints (singular /quiz/* paths).
extension TeacherQuizApi on QuizRepository {
  Future<Either<Failure, List<TeacherQuiz>>> teacherQuizzes(String teacherId) =>
      guardEither(() async {
        final res = await _dio.get('/quiz/teacher/$teacherId');
        return res
            .dataList(['quizzes'])
            .whereType<Map>()
            .map(TeacherQuiz.fromJson)
            .toList();
      });

  Future<Either<Failure, String>> createQuiz(Map<String, dynamic> body) =>
      guardEither(() async {
        final res = await _dio.post('/quiz', data: body);
        return res.dataMap().str(['_id', 'id']);
      });

  /// Updates a draft quiz. Mirrors React `quizApi.updateQuiz` →
  /// PUT `/quiz/:quizId` with any of `{ title, description, chapterIds,
  /// sectionIds, settings }`.
  Future<Either<Failure, Unit>> updateQuiz(
          String quizId, Map<String, dynamic> body) =>
      guardEither(() async {
        await _dio.put('/quiz/$quizId', data: body);
        return unit;
      });

  Future<Either<Failure, Unit>> publishQuiz(String quizId) =>
      guardEither(() async {
        await _dio.post('/quiz/$quizId/publish');
        return unit;
      });

  Future<Either<Failure, Unit>> closeQuiz(String quizId) =>
      guardEither(() async {
        await _dio.post('/quiz/$quizId/close');
        return unit;
      });

  Future<Either<Failure, Unit>> cloneQuiz(String quizId) =>
      guardEither(() async {
        await _dio.post('/quiz/$quizId/clone');
        return unit;
      });

  Future<Either<Failure, Unit>> deleteQuiz(String quizId,
          {bool force = false}) =>
      guardEither(() async {
        await _dio.delete('/quiz/$quizId',
            queryParameters: force ? {'forceDelete': 'true'} : null);
        return unit;
      });

  Future<Either<Failure, List<BankQuestion>>> searchBank({
    required String classId,
    required String subjectId,
    required List<String> chapterIds,
    String? difficulty,
  }) =>
      guardEither(() async {
        final res = await _dio.get('/quiz/questions/search', queryParameters: {
          'classId': classId,
          'subjectId': subjectId,
          'chapterIds': chapterIds.join(','),
          if (difficulty != null) 'difficulty': difficulty,
        });
        return res
            .dataList(['questions'])
            .whereType<Map>()
            .map(BankQuestion.fromJson)
            .toList();
      });

  /// Adds bank questions to a quiz with explicit per-question marks.
  /// Mirrors React `quizApi.addQuestions` body: `{ questions: [{ questionId, marks }] }`.
  Future<Either<Failure, Unit>> addQuestions(
    String quizId,
    List<String> questionIds, {
    Map<String, int> marksById = const {},
  }) =>
      guardEither(() async {
        await _dio.post('/quiz/$quizId/questions', data: {
          'questions': [
            for (final id in questionIds)
              {'questionId': id, 'marks': marksById[id] ?? 1},
          ],
        });
        return unit;
      });

  /// Loads a quiz's currently-attached questions (the teacher manager view).
  /// Mirrors React `quizApi.getQuiz` → `GET /quiz/:quizId` returning
  /// `{ quiz, questions }`; we surface the ordered `questions` list.
  Future<Either<Failure, List<QuizManagedQuestion>>> quizQuestions(
          String quizId) =>
      guardEither(() async {
        final res = await _dio.get('/quiz/$quizId');
        final data = res.dataMap();
        final list = data
            .listAt(['questions'])
            .whereType<Map>()
            .map(QuizManagedQuestion.fromJson)
            .toList();
        list.sort((a, b) => a.order.compareTo(b.order));
        return list;
      });

  /// Removes a single question from a quiz. Mirrors React `quizApi.removeQuestion`:
  /// DELETE `/quiz/:quizId/questions/:questionId`.
  Future<Either<Failure, Unit>> removeQuestion(
          String quizId, String questionId) =>
      guardEither(() async {
        await _dio.delete('/quiz/$quizId/questions/$questionId');
        return unit;
      });

  /// Reorders a quiz's questions. Mirrors React `quizApi.reorderQuestions`:
  /// PUT `/quiz/:quizId/questions/reorder` with body `{ order: [...quizQuestionIds] }`.
  Future<Either<Failure, Unit>> reorderQuestions(
          String quizId, List<String> orderedIds) =>
      guardEither(() async {
        await _dio.put('/quiz/$quizId/questions/reorder',
            data: {'order': orderedIds});
        return unit;
      });

  Future<Either<Failure, QuizAnalyticsData>> analytics(String quizId) =>
      guardEither(() async {
        final res = await _dio.get('/quiz/$quizId/analytics');
        return QuizAnalyticsData.fromJson(res.dataMap());
      });
}
