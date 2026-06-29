import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/study_config.dart';
import '../../domain/entities/study_enums.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/study_taxonomy.dart';
import '../../domain/entities/user_answer.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/session_usecases.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Drives the `/study` chat-style practice screen: the config funnel, the
/// one-question-at-a-time practice loop (batched fetch + batched submit with an
/// offline queue), and reviewing past sessions.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required SessionRepository repository,
    required GetClasses getClasses,
    required GetSubjects getSubjects,
    required GetChapters getChapters,
    required FetchQuestionBatch fetchQuestionBatch,
    required SubmitAnswers submitAnswers,
    required SyncQueuedAnswers syncQueuedAnswers,
    required SaveSession saveSession,
    required NetworkInfo networkInfo,
    int Function()? clock,
  })  : _repository = repository,
        _getClasses = getClasses,
        _getSubjects = getSubjects,
        _getChapters = getChapters,
        _fetchQuestionBatch = fetchQuestionBatch,
        _submitAnswers = submitAnswers,
        _syncQueuedAnswers = syncQueuedAnswers,
        _saveSession = saveSession,
        _networkInfo = networkInfo,
        _now = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
        super(const SessionState()) {
    on<SessionInitialised>(_onInit);
    on<ClassesRequested>(_onClasses);
    on<ClassSelected>(_onClassSelected);
    on<SubjectSelected>(_onSubjectSelected);
    on<ChapterSelected>(_onChapterSelected);
    on<QuestionTypeSelected>(_onQuestionType);
    on<DifficultySelected>(_onDifficulty);
    on<PracticeStarted>(_onStartPractice);
    on<ChapterPracticeStarted>(_onStartChapterPractice);
    on<AnswerSubmitted>(_onAnswer);
    on<NextQuestionRequested>(_onNext);
    on<SessionFinished>(_onFinish);
    on<ResultModalDismissed>(_onResultDismissed);
    on<NpsSubmitted>(_onNpsSubmitted);
    on<NpsDismissed>(_onNpsDismissed);
    on<SessionReviewOpened>(_onReview);
    on<SessionDeleted>(_onDelete);
    on<BackToConfigRequested>(_onBackToConfig);
    on<QuestionBatchRetried>(_onRetryBatch);
    on<ConnectivityChanged>(_onConnectivity);
  }

  final SessionRepository _repository;
  final GetClasses _getClasses;
  final GetSubjects _getSubjects;
  final GetChapters _getChapters;
  final FetchQuestionBatch _fetchQuestionBatch;
  final SubmitAnswers _submitAnswers;
  final SyncQueuedAnswers _syncQueuedAnswers;
  final SaveSession _saveSession;
  final NetworkInfo _networkInfo;
  final int Function() _now;

  StreamSubscription<bool>? _connSub;

  /// Answers collected since the last batch submit.
  final List<UserAnswer> _pending = [];

  /// The user whose session this is — stamped onto each answer's wire payload
  /// (the backend needs it to persist the answer and roll up progress).
  String _userId = '';

  /// When the current question was first shown, used to derive each answer's
  /// `timeSpent` (mirrors React's `questionStartTime`).
  int? _questionShownAtMillis;

  @override
  Future<void> close() {
    _connSub?.cancel();
    return super.close();
  }

  Future<void> _onInit(SessionInitialised e, Emitter<SessionState> emit) async {
    final online = await _networkInfo.isConnected;
    // Show the locally-cached history immediately for an instant, offline-safe
    // first paint.
    emit(state.copyWith(
      history: _repository.getSessionHistory(),
      isOnline: online,
    ));
    _connSub ??= _networkInfo.onConnectivityChanged.listen(
      (isOnline) => add(ConnectivityChanged(isOnline)),
    );
    if (online) add(const ConnectivityChanged(true));

    // The server is the source of truth for history (mirrors React's Sidebar
    // fetchSessionsByUserId). Refresh from it when we have a user and a network.
    if (online && e.userId.isNotEmpty) {
      emit(state.copyWith(historyStatus: LoadStatus.loading));
      final result = await _repository.fetchRemoteSessionHistory(e.userId);
      result.fold(
        (_) => emit(state.copyWith(historyStatus: LoadStatus.success)),
        (sessions) => emit(state.copyWith(
          history: sessions,
          historyStatus: LoadStatus.success,
        )),
      );
    }
  }

  Future<void> _onClasses(
    ClassesRequested e,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(taxonomyStatus: LoadStatus.loading, clearError: true));
    final result = await _getClasses(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(
        taxonomyStatus: LoadStatus.failure,
        errorMessage: f.message,
      )),
      (classes) => emit(state.copyWith(
        taxonomyStatus: LoadStatus.success,
        classes: classes,
      )),
    );
  }

  Future<void> _onClassSelected(
    ClassSelected e,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(
      config: state.config.copyWith(
        selectedClass: e.option,
        clearSubject: true,
        clearChapter: true,
      ),
      subjects: const [],
      chapters: const [],
      taxonomyStatus: LoadStatus.loading,
    ));
    final result = await _getSubjects(e.option.id);
    result.fold(
      (f) => emit(state.copyWith(
        taxonomyStatus: LoadStatus.failure,
        errorMessage: f.message,
      )),
      (subjects) => emit(state.copyWith(
        taxonomyStatus: LoadStatus.success,
        subjects: subjects,
      )),
    );
  }

  Future<void> _onSubjectSelected(
    SubjectSelected e,
    Emitter<SessionState> emit,
  ) async {
    final classId = state.config.selectedClass?.id ?? '';
    emit(state.copyWith(
      config: state.config.copyWith(
        selectedSubject: e.option,
        clearChapter: true,
      ),
      chapters: const [],
      taxonomyStatus: LoadStatus.loading,
    ));
    final result = await _getChapters(
      GetChaptersParams(classId: classId, subjectId: e.option.id),
    );
    result.fold(
      (f) => emit(state.copyWith(
        taxonomyStatus: LoadStatus.failure,
        errorMessage: f.message,
      )),
      (chapters) => emit(state.copyWith(
        taxonomyStatus: LoadStatus.success,
        chapters: chapters,
      )),
    );
  }

  void _onChapterSelected(ChapterSelected e, Emitter<SessionState> emit) {
    emit(state.copyWith(
      config: state.config.copyWith(selectedChapter: e.option),
    ));
  }

  void _onQuestionType(QuestionTypeSelected e, Emitter<SessionState> emit) {
    emit(state.copyWith(config: state.config.copyWith(questionType: e.type)));
  }

  void _onDifficulty(DifficultySelected e, Emitter<SessionState> emit) {
    emit(state.copyWith(
      config: state.config.copyWith(difficulty: e.difficulty),
    ));
  }

  Future<void> _onStartPractice(
    PracticeStarted e,
    Emitter<SessionState> emit,
  ) async {
    if (!state.config.isComplete) return;
    final cfg = state.config;
    _pending.clear();
    _userId = e.userId;
    _questionShownAtMillis = null;
    // Switch to the practice panel in a loading state while we create the
    // server-side session and fetch the first batch.
    emit(state.copyWith(
      panel: SessionPanel.practice,
      sessionStarted: true,
      questions: const [],
      currentIndex: 0,
      questionOffset: 0,
      seenQuestionIds: const {},
      answers: const {},
      clearFeedback: true,
      questionStatus: LoadStatus.loading,
      mastered: false,
    ));

    // The question-batch endpoint validates the session id as a MongoDB
    // ObjectId, so create the session on the backend first and use the id it
    // returns rather than a locally generated one.
    final created =
        await _repository.createSession(config: cfg, userId: e.userId);
    final sessionId = created.fold((_) => '', (id) => id);
    if (sessionId.isEmpty) {
      emit(state.copyWith(
        questionStatus: LoadStatus.failure,
        errorMessage:
            created.fold((f) => f.message, (_) => 'Could not start session'),
      ));
      return;
    }

    final session = StudySession(
      id: sessionId,
      className: cfg.selectedClass?.name ?? '',
      subjectName: cfg.selectedSubject?.name ?? '',
      chapterName: cfg.selectedChapter?.name ?? '',
      questionType: cfg.questionType,
      difficulty: cfg.difficulty,
      startedAtMillis: _now(),
    );
    emit(state.copyWith(activeSession: session));
    await _loadBatch(emit);
  }

  /// Fetches a batch and REPLACES the question list, resetting the index to 0 —
  /// mirroring React's `useQuestionPolling` (each batch holds only the current
  /// ~10 questions). Dedup is the backend's job, keyed by sessionId + the
  /// answers we submit before each fetch; nothing is appended, so a stale dupe
  /// can't accumulate across the session.
  Future<void> _loadBatch(Emitter<SessionState> emit,
      {bool retry = false}) async {
    final hadQuestions = state.questions.isNotEmpty;
    final sessionId = state.activeSession?.id ?? '';
    final result = await _fetchQuestionBatch(
      FetchBatchParams(
          config: state.config, sessionId: sessionId, retry: retry),
    );
    // The user may have pressed End (or dismissed the result modal) while the
    // batch was still polling. Emitting into an already-concluded session would
    // corrupt the state shown in the result modal or on the config screen.
    if (state.panel != SessionPanel.practice || state.resultSummary != null)
      return;
    if (result.isLeft()) {
      emit(state.copyWith(
        questionStatus: LoadStatus.failure,
        errorMessage: result.fold((f) => f.message, (_) => null),
      ));
      return;
    }

    final raw = result.getOrElse(() => const []);
    // Filter out questions the student has already seen this session.
    final batch =
        raw.where((q) => !state.seenQuestionIds.contains(q.id)).toList();
    if (batch.isEmpty) {
      // An empty terminal batch means the chapter is tapped out. If we'd already
      // shown questions this session, that's mastery (celebrate); otherwise the
      // selection had nothing to offer at all (error). Mirrors React's
      // mastered-vs-no-questions branch keyed on `everLoaded`.
      if (hadQuestions) {
        emit(
            state.copyWith(questionStatus: LoadStatus.success, mastered: true));
      } else {
        emit(state.copyWith(
          questionStatus: LoadStatus.failure,
          errorMessage:
              'No questions are available for this selection yet. Please try again later.',
        ));
      }
      return;
    }

    // Advance the running question number by the size of the PREVIOUS batch so
    // the counter shows "Question 11, 12, …" instead of resetting to 1.
    final newOffset = retry
        ? state.questionOffset
        : state.questionOffset + state.questions.length;

    emit(state.copyWith(
      questionStatus: LoadStatus.success,
      questions: batch, // REPLACE — not append
      currentIndex: 0, // reset to the first question of the new batch
      questionOffset: newOffset,
      seenQuestionIds: {...state.seenQuestionIds, ...batch.map((q) => q.id)},
      mastered: false,
    ));
    _questionShownAtMillis =
        _now(); // first question of the new batch is now visible
  }

  /// Pre-fills the config from a chapter chosen elsewhere (the Progress page)
  /// and reuses the normal start path, so the user lands straight on the
  /// question loop instead of the config funnel.
  Future<void> _onStartChapterPractice(
    ChapterPracticeStarted e,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(
      config: StudyConfig(
        selectedClass: e.classOption,
        selectedSubject: e.subject,
        selectedChapter: e.chapter,
      ),
      originRoute: e.returnRoute,
    ));
    await _onStartPractice(PracticeStarted(userId: e.userId), emit);
  }

  Future<void> _onAnswer(AnswerSubmitted e, Emitter<SessionState> emit) async {
    final q = state.currentQuestion;
    if (q == null || state.hasAnsweredCurrent) return;

    final correct = q.isCorrect(e.answer);
    final cfg = state.config;
    // 0-based count of answers already given this session, used to derive the
    // 1-based sequence/batch numbers the backend expects (mirrors React).
    final seq = state.answers.length;
    final now = _now();
    final timeSpent = _questionShownAtMillis == null
        ? 1
        : ((now - _questionShownAtMillis!) / 1000).round().clamp(1, 1 << 30);
    final answer = UserAnswer(
      questionId: q.id,
      sessionId: state.activeSession?.id ?? '',
      answer: e.answer,
      isCorrect: correct,
      answeredAtMillis: now,
      // Context the backend needs to persist the answer (mirrors React's
      // `submitUserAnswers` payload). Without these the answer is dropped and
      // the session reads back empty with a 0 score.
      userId: _userId,
      subjectId: cfg.selectedSubject?.id,
      chapterId: cfg.selectedChapter?.id ?? q.chapterId,
      subject: cfg.selectedSubject?.name,
      chapter: cfg.selectedChapter?.name,
      difficulty: cfg.difficulty.apiValue.toLowerCase(),
      questionType: cfg.questionType.apiValue,
      batchNumber: (seq ~/ AppConstants.answerSubmitBatchSize) + 1,
      sessionSequence: seq + 1,
      timeSpentSeconds: timeSpent,
    );
    _pending.add(answer);

    final answers = Map<String, UserAnswer>.from(state.answers)
      ..[q.id] = answer;

    emit(state.copyWith(
      answers: answers,
      feedback: AnswerFeedback(
        isCorrect: correct,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
      ),
    ));

    // Flush answers in batches.
    if (_pending.length >= AppConstants.answerSubmitBatchSize) {
      await _flushPending(emit);
    }
  }

  Future<void> _flushPending(Emitter<SessionState> emit) async {
    if (_pending.isEmpty) return;
    final batch = List<UserAnswer>.from(_pending);
    _pending.clear();
    await _submitAnswers(batch);
    final queued =
        state.isOnline ? state.queuedCount : state.queuedCount + batch.length;
    emit(state.copyWith(queuedCount: queued));
  }

  Future<void> _onNext(
    NextQuestionRequested e,
    Emitter<SessionState> emit,
  ) async {
    // Within the current batch → just advance the index.
    if (state.currentIndex < state.questions.length - 1) {
      emit(state.copyWith(
          currentIndex: state.currentIndex + 1, clearFeedback: true));
      _questionShownAtMillis = _now();
      return;
    }

    // End of the batch → submit answers FIRST so the backend can exclude them,
    // then fetch the next batch (which REPLACES the list + resets the index).
    // Mirrors React: submitAnswerBatch(...) then loadQuestions(true).
    if (state.questionStatus == LoadStatus.loading) return;
    emit(state.copyWith(
        questionStatus: LoadStatus.loading, clearFeedback: true));
    await _flushPending(emit);
    await _loadBatch(emit);
  }

  Future<void> _onFinish(SessionFinished e, Emitter<SessionState> emit) async {
    if (state.resultSummary != null || state.finishing)
      return; // already finishing
    // Surface the loader on the End button for the duration of the close calls.
    emit(state.copyWith(finishing: true));
    // Flush any answers collected since the last batch (mirrors React's
    // submitUserAnswers before endSession).
    await _flushPending(emit);

    final score = state.correctCount;
    final total = state.answeredCount;
    final summary = SessionSummary(score: score, total: total);

    // Close the server-side session with its final score (React `endSession`).
    // Best-effort: a failure here must not block the result modal.
    final active = state.activeSession;
    if (active != null) {
      await _repository.endSession(
        sessionId: active.id,
        score: score,
        totalQuestions: total,
      );

      final completed = active.copyWith(
        answers: state.answers.values.toList(),
        // Cumulative session total — `questions` now holds only the latest
        // batch (replace model), so use the count of answers given.
        totalQuestions: total,
        completed: true,
      );
      await _saveSession(completed);
      emit(state.copyWith(history: _repository.getSessionHistory()));
    }

    // Ask the server whether this user is due an NPS survey (React checks this
    // in the background right after ending the session).
    var npsEligible = false;
    if (e.userId.isNotEmpty) {
      final result = await _repository.checkNpsEligibility(e.userId);
      npsEligible = result.fold((_) => false, (eligible) => eligible);
    }

    // Keep the practice panel mounted; the result modal overlays it. The reset
    // to the config panel happens once the modal is dismissed.
    emit(state.copyWith(
      resultSummary: summary,
      npsHandled: false,
      npsEligible: npsEligible,
      finishing: false,
    ));

    // With the modal now up, refresh history from the server so the full
    // session list shows (not just locally-saved sessions) and the
    // just-finished session is server-sourced — its review then lazy-loads
    // answers with question detail from `user-answers/session/:id` instead of
    // showing the bare local answers. Mirrors React re-fetching
    // `fetchSessionsByUserId` on returning to the dashboard. The instant local
    // emit above keeps the list correct offline; this updates it underneath the
    // modal when online. Best-effort: keep the local list on failure.
    if (state.isOnline && e.userId.isNotEmpty) {
      final remote = await _repository.fetchRemoteSessionHistory(e.userId);
      remote.fold(
        (_) {}, // keep the locally-emitted history on failure
        (sessions) => emit(state.copyWith(history: sessions)),
      );
    }
  }

  void _onResultDismissed(
    ResultModalDismissed e,
    Emitter<SessionState> emit,
  ) {
    _pending.clear();
    emit(state.copyWith(
      panel: SessionPanel.config,
      sessionStarted: false,
      // Reset the config funnel to its default state so the first screen starts
      // fresh (back to step 1) rather than retaining the last session's picks.
      config: const StudyConfig(),
      subjects: const [],
      chapters: const [],
      questions: const [],
      currentIndex: 0,
      questionOffset: 0,
      seenQuestionIds: const {},
      answers: const {},
      clearFeedback: true,
      clearError: true,
      clearResultSummary: true,
      finishing: false,
      mastered: false,
      // Clearing the origin is the signal the launching screen (e.g. Progress)
      // listens for to return to itself and refresh.
      clearOrigin: true,
    ));
  }

  Future<void> _onNpsSubmitted(
    NpsSubmitted e,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(npsHandled: true));
    await _repository.submitNps(
      userId: e.userId,
      npsScore: e.score,
      comment: e.comment,
    );
  }

  void _onNpsDismissed(NpsDismissed e, Emitter<SessionState> emit) {
    emit(state.copyWith(npsHandled: true));
  }

  Future<void> _onReview(
    SessionReviewOpened e,
    Emitter<SessionState> emit,
  ) async {
    final session = state.history.firstWhere(
      (s) => s.id == e.sessionId,
      orElse: () => state.history.isNotEmpty
          ? state.history.first
          : throw StateError('No session'),
    );

    // Pull the recorded answers from the server on demand (React's
    // fetchUserAnswersBySession), unless we already have them locally.
    if (session.answers.isEmpty && state.isOnline) {
      // Show the review panel in loading state while we fetch answers.
      emit(state.copyWith(
        panel: SessionPanel.review,
        reviewSession: session,
        reviewStatus: LoadStatus.loading,
      ));
      final result = await _repository.fetchSessionAnswers(session.id);
      result.fold(
        (_) {
          if (state.reviewSession?.id != session.id) return;
          emit(state.copyWith(reviewStatus: LoadStatus.success));
        },
        (answers) {
          // Guard against the user navigating away while the fetch was in flight.
          if (state.reviewSession?.id != session.id) return;
          emit(state.copyWith(
            reviewSession: session.copyWith(answers: answers),
            reviewStatus: LoadStatus.success,
          ));
        },
      );
    } else {
      // Answers already cached locally — show immediately.
      emit(state.copyWith(
        panel: SessionPanel.review,
        reviewSession: session,
        reviewStatus: LoadStatus.success,
      ));
    }
  }

  Future<void> _onDelete(SessionDeleted e, Emitter<SessionState> emit) async {
    await _repository.deleteSession(e.sessionId);
    // Drop it from the in-memory list rather than re-reading local storage,
    // which would clobber the server-loaded history with local-only sessions.
    emit(state.copyWith(
      history: state.history.where((s) => s.id != e.sessionId).toList(),
    ));
  }

  void _onBackToConfig(BackToConfigRequested e, Emitter<SessionState> emit) {
    _pending.clear();
    emit(state.copyWith(
      panel: SessionPanel.config,
      sessionStarted: false,
      config: const StudyConfig(),
      subjects: const [],
      chapters: const [],
      questions: const [],
      currentIndex: 0,
      questionOffset: 0,
      seenQuestionIds: const {},
      answers: const {},
      questionStatus: LoadStatus.idle,
      taxonomyStatus: LoadStatus.idle,
      clearFeedback: true,
      clearError: true,
      clearResultSummary: true,
      clearReviewSession: true,
      finishing: false,
      mastered: false,
      // intentionally NOT clearing originRoute — that is only cleared by
      // _onResultDismissed so the Progress page listener doesn't fire here.
    ));
  }

  Future<void> _onRetryBatch(
    QuestionBatchRetried e,
    Emitter<SessionState> emit,
  ) async {
    if (state.activeSession == null) return;
    emit(state.copyWith(
        questionStatus: LoadStatus.loading, clearError: true, mastered: false));
    await _loadBatch(emit, retry: true);
  }

  Future<void> _onConnectivity(
    ConnectivityChanged e,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(isOnline: e.isOnline));
    if (e.isOnline) {
      final result = await _syncQueuedAnswers(const NoParams());
      result.fold(
        (_) {},
        (synced) {
          if (synced > 0) emit(state.copyWith(queuedCount: 0));
        },
      );
    }
  }
}
