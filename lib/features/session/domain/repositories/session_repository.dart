import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/question.dart';
import '../entities/study_config.dart';
import '../entities/study_session.dart';
import '../entities/study_taxonomy.dart';
import '../entities/user_answer.dart';

/// Domain contract for the study/practice flow. Combines remote question
/// fetching with local session history and an offline answer queue.
abstract class SessionRepository {
  // --- Configuration funnel ---
  Future<Either<Failure, List<ClassOption>>> getClasses();
  Future<Either<Failure, List<SubjectOption>>> getSubjects(String classId);
  Future<Either<Failure, List<ChapterOption>>> getChapters(
    String classId,
    String subjectId,
  );

  // --- Questions (batched, with AI fallback + retries handled in impl) ---
  Future<Either<Failure, List<Question>>> fetchQuestionBatch({
    required StudyConfig config,
    required String sessionId,
  });

  // --- Answers ---
  /// Submits a batch of answers. When offline, persists them to the queue and
  /// returns success so the UI can proceed; they sync on reconnect.
  Future<Either<Failure, Unit>> submitAnswers(List<UserAnswer> answers);

  /// Pushes any queued offline answers to the server. Returns how many synced.
  Future<Either<Failure, int>> syncQueuedAnswers();

  // --- Post-session feedback ---
  /// Submits a Net Promoter Score response (0–10 + optional comment) to
  /// `/session-feedback/nps`. Mirrors React's `studyApi.submitNps`.
  Future<Either<Failure, Unit>> submitNps({
    required String userId,
    required int npsScore,
    String? comment,
  });

  // --- Local session history ---
  List<StudySession> getSessionHistory();
  Future<Either<Failure, Unit>> saveSession(StudySession session);
  Future<Either<Failure, Unit>> deleteSession(String sessionId);
}
