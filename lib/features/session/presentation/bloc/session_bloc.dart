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
    on<AnswerSubmitted>(_onAnswer);
    on<NextQuestionRequested>(_onNext);
    on<SessionFinished>(_onFinish);
    on<ResultModalDismissed>(_onResultDismissed);
    on<NpsSubmitted>(_onNpsSubmitted);
    on<NpsDismissed>(_onNpsDismissed);
    on<SessionReviewOpened>(_onReview);
    on<SessionDeleted>(_onDelete);
    on<BackToConfigRequested>(_onBackToConfig);
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
      final result = await _repository.fetchRemoteSessionHistory(e.userId);
      result.fold(
        (_) {}, // keep the cached history on failure
        (sessions) => emit(state.copyWith(history: sessions)),
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
    // Switch to the practice panel in a loading state while we create the
    // server-side session and fetch the first batch.
    emit(state.copyWith(
      panel: SessionPanel.practice,
      sessionStarted: true,
      questions: const [],
      currentIndex: 0,
      answers: const {},
      clearFeedback: true,
      questionStatus: LoadStatus.loading,
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

  Future<void> _loadBatch(Emitter<SessionState> emit) async {
    final sessionId = state.activeSession?.id ?? '';
    final result = await _fetchQuestionBatch(
      FetchBatchParams(config: state.config, sessionId: sessionId),
    );
    result.fold(
      (f) => emit(state.copyWith(
        questionStatus: LoadStatus.failure,
        errorMessage: f.message,
      )),
      (batch) => emit(state.copyWith(
        questionStatus: LoadStatus.success,
        questions: [...state.questions, ...batch],
      )),
    );
  }

  Future<void> _onAnswer(AnswerSubmitted e, Emitter<SessionState> emit) async {
    final q = state.currentQuestion;
    if (q == null || state.hasAnsweredCurrent) return;

    final correct = q.isCorrect(e.answer);
    final answer = UserAnswer(
      questionId: q.id,
      sessionId: state.activeSession?.id ?? '',
      answer: e.answer,
      isCorrect: correct,
      answeredAtMillis: _now(),
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
    final queued = state.isOnline ? state.queuedCount : state.queuedCount + batch.length;
    emit(state.copyWith(queuedCount: queued));
  }

  Future<void> _onNext(
    NextQuestionRequested e,
    Emitter<SessionState> emit,
  ) async {
    final nextIndex = state.currentIndex + 1;
    emit(state.copyWith(currentIndex: nextIndex, clearFeedback: true));

    // Prefetch the next batch when nearing the end of the current one.
    final remaining = state.questions.length - nextIndex;
    if (remaining <= 1 && state.questionStatus != LoadStatus.loading) {
      emit(state.copyWith(questionStatus: LoadStatus.loading));
      await _loadBatch(emit);
    }
  }

  Future<void> _onFinish(SessionFinished e, Emitter<SessionState> emit) async {
    if (state.resultSummary != null) return; // already finishing
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
        totalQuestions: state.questions.length,
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
    ));
  }

  void _onResultDismissed(
    ResultModalDismissed e,
    Emitter<SessionState> emit,
  ) {
    _pending.clear();
    emit(state.copyWith(
      panel: SessionPanel.config,
      sessionStarted: false,
      questions: const [],
      currentIndex: 0,
      answers: const {},
      clearFeedback: true,
      clearResultSummary: true,
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
    // Show the review immediately with whatever answers we have cached.
    emit(state.copyWith(panel: SessionPanel.review, reviewSession: session));

    // Pull the recorded answers from the server on demand (React's
    // fetchUserAnswersBySession), unless we already have them locally.
    if (session.answers.isEmpty && state.isOnline) {
      final result = await _repository.fetchSessionAnswers(session.id);
      result.fold(
        (_) {},
        (answers) {
          // Guard against the user navigating away while the fetch was in flight.
          if (state.reviewSession?.id != session.id) return;
          emit(state.copyWith(
            reviewSession: session.copyWith(answers: answers),
          ));
        },
      );
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
    emit(state.copyWith(panel: SessionPanel.config, clearFeedback: true));
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
