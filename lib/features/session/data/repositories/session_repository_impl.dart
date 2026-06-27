import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/taxonomy/taxonomy_repository.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/study_config.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/study_taxonomy.dart';
import '../../domain/entities/user_answer.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_datasource.dart';
import '../datasources/session_remote_datasource.dart';

/// Implements the study flow:
///  - question batches are fetched with retries (the server applies an AI
///    fallback when its bank is short; we retry on empty/transient errors),
///  - answers submit live when online, otherwise queue and sync on reconnect,
///  - session history lives entirely in local storage.
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({
    required SessionRemoteDataSource remote,
    required SessionLocalDataSource local,
    required NetworkInfo networkInfo,
    required TaxonomyRepository taxonomy,
  })  : _remote = remote,
        _local = local,
        _network = networkInfo,
        _taxonomy = taxonomy;

  final SessionRemoteDataSource _remote;
  final SessionLocalDataSource _local;
  final NetworkInfo _network;

  /// Shared taxonomy source of truth (also used by the quiz builder and
  /// question-paper generator). The study funnel maps its [TaxItem]s onto the
  /// richer study domain entities below.
  final TaxonomyRepository _taxonomy;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      final inner = e.error;
      if (inner is ServerException) {
        return Left(ServerFailure(inner.message, statusCode: inner.statusCode));
      }
      if (inner is NetworkException) return Left(NetworkFailure(inner.message));
      if (inner is UnauthorizedException) {
        return Left(UnauthorizedFailure(inner.message));
      }
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // The class → subject → chapter funnel delegates to the shared
  // [TaxonomyRepository] (same endpoints the quiz builder / paper generator
  // use) and maps the generic TaxItems onto the study domain entities.
  @override
  Future<Either<Failure, List<ClassOption>>> getClasses() =>
      _taxonomy.classes().then((e) => e.map((items) =>
          items.map((t) => ClassOption(id: t.id, name: t.name)).toList()));

  @override
  Future<Either<Failure, List<SubjectOption>>> getSubjects(String classId) =>
      _taxonomy.subjects(classId).then((e) => e.map((items) => items
          .map((t) => SubjectOption(id: t.id, name: t.name, classId: classId))
          .toList()));

  @override
  Future<Either<Failure, List<ChapterOption>>> getChapters(
    String classId,
    String subjectId,
  ) =>
      _taxonomy.chapters(classId, subjectId).then((e) => e.map((items) => items
          .map((t) => ChapterOption(
                id: t.id,
                name: t.name,
                number: t.number,
                subjectId: subjectId,
                comingSoon: t.comingSoon,
                isStartable: t.isStartable,
              ))
          .toList()));

  @override
  Future<Either<Failure, String>> createSession({
    required StudyConfig config,
    required String userId,
  }) =>
      _guard(() async {
        // Field shape mirrors the React frontend's `studyApi.startSession`
        // config: ids + display names, with a first-letter-capitalised
        // difficulty (e.g. 'Medium').
        final id = await _remote.createSession({
          'userId': userId,
          'classId': config.selectedClass?.id ?? '',
          'subject': config.selectedSubject?.name ?? '',
          'subjectId': config.selectedSubject?.id ?? '',
          'chapter': config.selectedChapter?.name ?? '',
          'chapterId': config.selectedChapter?.id ?? '',
          'questionType': config.questionType.apiValue,
          'difficulty': config.difficulty.apiValue,
        });
        if (id.isEmpty) {
          throw ServerException('Session created without an id');
        }
        return id;
      });

  @override
  Future<Either<Failure, List<Question>>> fetchQuestionBatch({
    required StudyConfig config,
    required String sessionId,
    bool retry = false,
  }) {
    final chapterId = config.selectedChapter?.id ?? '';
    return _guard(() async {
      // Mirrors the frontend's `useQuestionPolling`: while the server is still
      // AI-generating a batch we poll (~3s apart, up to ~60s); a `failed`
      // generation is retried a few times with `retry=true` (mirrors React's
      // re-kick); a request timeout is treated as "generation is taking long".
      var generatingPolls = 0;
      var failedRetries = 0;
      // First call uses the caller-supplied retry flag; subsequent failed
      // retries always pass retry=true so the backend re-generates.
      var useRetry = retry;
      while (true) {
        QuestionBatchResult result;
        try {
          result = await _remote.fetchQuestionBatch(
            chapterId: chapterId,
            type: config.questionType.apiValue,
            difficulty: config.difficulty.apiValue,
            sessionId: sessionId,
            retry: useRetry,
          );
        } on DioException catch (e) {
          final timedOut = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout;
          if (timedOut && generatingPolls < AppConstants.questionGeneratingPollLimit) {
            generatingPolls++;
            await Future<void>.delayed(AppConstants.questionFailedRetryDelay);
            continue;
          }
          rethrow;
        }

        switch (result.status) {
          case QuestionBatchStatus.ready:
            return result.questions.map((m) => m.toEntity()).toList();
          case QuestionBatchStatus.mastered:
            // Terminal: the chapter is exhausted. Return an empty list — the
            // bloc reads "empty success after a batch was loaded" as mastered.
            return const [];
          case QuestionBatchStatus.generating:
            if (generatingPolls >= AppConstants.questionGeneratingPollLimit) {
              throw ServerException(
                  'Questions are still being generated. Please try again in a moment.');
            }
            generatingPolls++;
            useRetry = false; // normal poll, no re-generation needed
            await Future<void>.delayed(AppConstants.questionGeneratingPollInterval);
            continue;
          case QuestionBatchStatus.failed:
            if (failedRetries >= AppConstants.batchRetryLimit) {
              throw ServerException(
                  'Unable to generate more questions right now. Please try again later.');
            }
            failedRetries++;
            useRetry = true; // re-kick generation, mirrors React ?retry=true
            await Future<void>.delayed(AppConstants.questionFailedRetryDelay);
            continue;
        }
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> submitAnswers(List<UserAnswer> answers) async {
    if (answers.isEmpty) return const Right(unit);

    if (!await _network.isConnected) {
      _local.enqueueAnswers(answers);
      return const Right(unit); // optimistic: queued for later sync
    }

    try {
      await _remote.submitAnswers(answers.map((a) => a.toWireJson()).toList());
      return const Right(unit);
    } catch (_) {
      // Network hiccup mid-submit — fall back to the queue rather than fail.
      _local.enqueueAnswers(answers);
      return const Right(unit);
    }
  }

  @override
  Future<Either<Failure, int>> syncQueuedAnswers() async {
    final queued = _local.readQueuedAnswers();
    if (queued.isEmpty) return const Right(0);
    if (!await _network.isConnected) return const Left(NetworkFailure());

    return _guard(() async {
      await _remote.submitAnswers(queued.map((a) => a.toWireJson()).toList());
      await _local.clearQueuedAnswers(_local.queuedKeys());
      return queued.length;
    });
  }

  @override
  Future<Either<Failure, Unit>> submitNps({
    required String userId,
    required int npsScore,
    String? comment,
  }) =>
      _guard(() async {
        await _remote.submitNps({
          'userId': userId,
          'npsScore': npsScore,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        });
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> endSession({
    required String sessionId,
    required int score,
    required int totalQuestions,
  }) =>
      _guard(() async {
        await _remote.endSession(sessionId, score, totalQuestions);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> submitSessionReaction(Map<String, dynamic> data) =>
      _guard(() async {
        await _remote.submitReaction(data);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> submitFeedback({
    required String name,
    required String feedback,
    String? email,
  }) =>
      _guard(() async {
        await _remote.submitFeedback(name: name, feedback: feedback, email: email);
        return unit;
      });

  @override
  Future<Either<Failure, bool>> checkNpsEligibility(String userId) =>
      _guard(() => _remote.checkNpsEligibility(userId));

  @override
  Future<Either<Failure, Map<String, dynamic>>> completeDailyChallenge({
    required String userId,
    required List<Map<String, dynamic>> answers,
  }) =>
      _guard(() => _remote.completeDailyChallenge(userId, answers));

  @override
  Future<Either<Failure, Unit>> useStreakFreeze(String userId) =>
      _guard(() async {
        await _remote.useStreakFreeze(userId);
        return unit;
      });

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getShareCard(String sessionId) =>
      _guard(() => _remote.getShareCard(sessionId));

  @override
  Future<Either<Failure, List<dynamic>>> checkNewBadges({
    required String userId,
    required Map<String, dynamic> sessionData,
  }) =>
      _guard(() => _remote.checkNewBadges(userId, sessionData));

  @override
  List<StudySession> getSessionHistory() => _local.readHistory();

  @override
  Future<Either<Failure, List<StudySession>>> fetchRemoteSessionHistory(
    String userId,
  ) =>
      _guard(() async {
        final sessions = await _remote.fetchSessionsByUserId(userId);
        sessions.sort((a, b) => b.startedAtMillis.compareTo(a.startedAtMillis));
        return sessions;
      });

  @override
  Future<Either<Failure, List<UserAnswer>>> fetchSessionAnswers(
    String sessionId,
  ) =>
      _guard(() => _remote.fetchUserAnswersBySession(sessionId));

  @override
  Future<Either<Failure, Unit>> saveSession(StudySession session) =>
      _guard(() async {
        await _local.upsertSession(session);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteSession(String sessionId) =>
      _guard(() async {
        await _local.deleteSession(sessionId);
        return unit;
      });
}
