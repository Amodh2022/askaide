import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
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
  })  : _remote = remote,
        _local = local,
        _network = networkInfo;

  final SessionRemoteDataSource _remote;
  final SessionLocalDataSource _local;
  final NetworkInfo _network;

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

  @override
  Future<Either<Failure, List<ClassOption>>> getClasses() =>
      _guard(_remote.getClasses);

  @override
  Future<Either<Failure, List<SubjectOption>>> getSubjects(String classId) =>
      _guard(() => _remote.getSubjects(classId));

  @override
  Future<Either<Failure, List<ChapterOption>>> getChapters(
    String classId,
    String subjectId,
  ) =>
      _guard(() => _remote.getChapters(classId, subjectId));

  @override
  Future<Either<Failure, List<Question>>> fetchQuestionBatch({
    required StudyConfig config,
    required String sessionId,
  }) {
    final chapterId = config.selectedChapter?.id ?? '';
    return _guard(() async {
      Object? lastError;
      // Retry to ride out empty responses while the server's AI fallback
      // generates fresh questions.
      for (var attempt = 0; attempt < AppConstants.batchRetryLimit; attempt++) {
        try {
          final models = await _remote.fetchQuestionBatch(
            chapterId: chapterId,
            type: config.questionType.apiValue,
            difficulty: config.difficulty.apiValue,
            sessionId: sessionId,
          );
          final questions = models.map((m) => m.toEntity()).toList();
          if (questions.isNotEmpty) return questions;
        } catch (e) {
          lastError = e;
        }
      }
      if (lastError is Exception) throw lastError;
      throw ServerException('No questions available after retries');
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
      await _remote.submitAnswers(answers.map((a) => a.toJson()).toList());
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
      await _remote.submitAnswers(queued.map((a) => a.toJson()).toList());
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
  List<StudySession> getSessionHistory() => _local.readHistory();

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
