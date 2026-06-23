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

  // --- Remote session lifecycle ---
  /// Creates a server-side study session and returns its MongoDB ObjectId.
  /// The question-batch endpoint validates the session id as an ObjectId, so a
  /// real session must be created first. Mirrors React's `studyApi.startSession`.
  Future<Either<Failure, String>> createSession({
    required StudyConfig config,
    required String userId,
  });

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

  /// Closes the server-side session with the final score (React `endSession`).
  Future<Either<Failure, Unit>> endSession({
    required String sessionId,
    required int score,
    required int totalQuestions,
  });

  /// Submits an emoji reaction after a session (React `submitSessionReaction`).
  Future<Either<Failure, Unit>> submitSessionReaction(Map<String, dynamic> data);

  /// Whether the post-session NPS survey should be shown for [userId].
  Future<Either<Failure, bool>> checkNpsEligibility(String userId);

  /// Completes today's daily challenge with the given answers.
  Future<Either<Failure, Map<String, dynamic>>> completeDailyChallenge({
    required String userId,
    required List<Map<String, dynamic>> answers,
  });

  /// Spends one streak freeze for [userId].
  Future<Either<Failure, Unit>> useStreakFreeze(String userId);

  /// Share-card payload for a completed session (null when unavailable).
  Future<Either<Failure, Map<String, dynamic>?>> getShareCard(String sessionId);

  /// Returns ids of badges newly earned after a session.
  Future<Either<Failure, List<dynamic>>> checkNewBadges({
    required String userId,
    required Map<String, dynamic> sessionData,
  });

  // --- Local session history ---
  List<StudySession> getSessionHistory();
  Future<Either<Failure, Unit>> saveSession(StudySession session);
  Future<Either<Failure, Unit>> deleteSession(String sessionId);
}
