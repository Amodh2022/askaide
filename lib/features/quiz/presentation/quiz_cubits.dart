import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/quiz_models.dart';
import '../data/quiz_repository.dart';

enum Load { initial, loading, loaded, error }

// ---------------------------------------------------------------------------
// Quiz list (available + history)
// ---------------------------------------------------------------------------
class QuizListState extends Equatable {
  const QuizListState({
    this.status = Load.initial,
    this.available = const [],
    this.history = const [],
    this.pagination = const QuizPagination(),
    this.error,
  });
  final Load status;
  final List<QuizSummary> available;
  final List<QuizHistoryItem> history;
  final QuizPagination pagination;
  final String? error;

  QuizListState copyWith({
    Load? status,
    List<QuizSummary>? available,
    List<QuizHistoryItem>? history,
    QuizPagination? pagination,
    String? error,
  }) =>
      QuizListState(
        status: status ?? this.status,
        available: available ?? this.available,
        history: history ?? this.history,
        pagination: pagination ?? this.pagination,
        error: error,
      );

  @override
  List<Object?> get props => [status, available, history, pagination, error];
}

class QuizListCubit extends Cubit<QuizListState> {
  QuizListCubit(this._repo) : super(const QuizListState());
  final QuizRepository _repo;

  Future<void> loadAvailable({
    int page = 1,
    int limit = 12,
    String? status,
    String? subjectId,
  }) async {
    emit(state.copyWith(status: Load.loading));
    final r = await _repo.available(
      page: page,
      limit: limit,
      status: status,
      subjectId: subjectId,
    );
    r.fold(
      (f) => emit(state.copyWith(status: Load.error, error: f.message)),
      (pageData) => emit(state.copyWith(
        status: Load.loaded,
        available: pageData.items,
        pagination: pageData.pagination,
        error: null,
      )),
    );
  }

  Future<void> loadHistory({
    int page = 1,
    int limit = 10,
    String? subjectId,
  }) async {
    emit(state.copyWith(status: Load.loading));
    final r = await _repo.history(
      page: page,
      limit: limit,
      subjectId: subjectId,
    );
    r.fold(
      (f) => emit(state.copyWith(status: Load.error, error: f.message)),
      (pageData) => emit(state.copyWith(
        status: Load.loaded,
        history: pageData.items,
        pagination: pageData.pagination,
        error: null,
      )),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz attempt
// ---------------------------------------------------------------------------
sealed class QuizSessionState extends Equatable {
  const QuizSessionState();
}

class QuizSessionLoading extends QuizSessionState {
  const QuizSessionLoading();
  @override
  List<Object?> get props => [];
}

class QuizSessionFailed extends QuizSessionState {
  const QuizSessionFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

/// Common base once an attempt has loaded — carries everything the question
/// UI needs, so widgets can depend on this instead of the full session state.
sealed class QuizSessionLoaded extends QuizSessionState {
  const QuizSessionLoaded({
    required this.attempt,
    required this.index,
    required this.answers,
    required this.flagged,
  });
  final QuizAttempt attempt;
  final int index;
  final Map<String, String> answers; // quizQuestionId -> selectedAnswer
  final Set<String> flagged; // quizQuestionIds marked for review

  QuizQuestion? get current =>
      index >= 0 && index < attempt.questions.length
          ? attempt.questions[index]
          : null;
  int get total => attempt.questions.length;
  int get answeredCount => answers.length;
  int get flaggedCount => flagged.length;

  @override
  List<Object?> get props => [attempt, index, answers, flagged];
}

class QuizInProgress extends QuizSessionLoaded {
  const QuizInProgress({
    required super.attempt,
    required super.index,
    required super.answers,
    required super.flagged,
  });
}

class QuizSubmitting extends QuizSessionLoaded {
  const QuizSubmitting({
    required super.attempt,
    required super.index,
    required super.answers,
    required super.flagged,
  });
}

class QuizSubmitted extends QuizSessionLoaded {
  const QuizSubmitted({
    required super.attempt,
    required super.index,
    required super.answers,
    required super.flagged,
    required this.attemptId,
  });
  final String attemptId;
  @override
  List<Object?> get props => [...super.props, attemptId];
}

class QuizAttemptCubit extends Cubit<QuizSessionState> {
  QuizAttemptCubit(this._repo) : super(const QuizSessionLoading());
  final QuizRepository _repo;

  /// When the current question was first shown — the anchor for the per-answer
  /// `timeSpent` we report, reset on every navigation (mirrors the frontend's
  /// `questionStartTime` ref).
  DateTime _questionEnteredAt = DateTime.now();

  /// Starts (or resumes) an attempt for a quiz. The `/start` endpoint is
  /// resume-or-create: for an in-progress attempt it returns the same attempt
  /// with its previously-saved answers, which we hydrate into the state.
  Future<void> start(String quizId) async {
    emit(const QuizSessionLoading());
    final r = await _repo.start(quizId);
    r.fold(
      (f) => emit(QuizSessionFailed(f.message)),
      _onAttemptLoaded,
    );
  }

  /// Resumes / loads an existing attempt by id.
  Future<void> load(String attemptId) async {
    emit(const QuizSessionLoading());
    final r = await _repo.getAttempt(attemptId);
    r.fold(
      (f) => emit(QuizSessionFailed(f.message)),
      _onAttemptLoaded,
    );
  }

  /// Shared post-load: restore any previously-saved answers and reset the
  /// per-question timer (mirrors the frontend's `setAnswers(savedAnswers)`).
  void _onAttemptLoaded(QuizAttempt a) {
    _questionEnteredAt = DateTime.now();
    emit(QuizInProgress(
      attempt: a,
      index: 0,
      answers: Map<String, String>.from(a.savedAnswers),
      flagged: const {},
    ));
  }

  void select(String answer) {
    final s = state;
    if (s is! QuizInProgress) return;
    final q = s.current;
    if (q == null) return;
    final next = Map<String, String>.from(s.answers)..[q.id] = answer;
    emit(QuizInProgress(
        attempt: s.attempt, index: s.index, answers: next, flagged: s.flagged));
    // Fire-and-forget per-question save (mirrors the frontend autosave),
    // reporting the seconds spent on this question since it was shown.
    final timeSpent = DateTime.now()
        .difference(_questionEnteredAt)
        .inSeconds
        .clamp(0, 1 << 31);
    _repo.answer(s.attempt.attemptId,
        quizQuestionId: q.id, selectedAnswer: answer, timeSpent: timeSpent);
  }

  void goTo(int i) {
    final s = state;
    if (s is! QuizInProgress) return;
    if (i >= 0 && i < s.total) {
      _questionEnteredAt = DateTime.now();
      emit(QuizInProgress(
          attempt: s.attempt, index: i, answers: s.answers, flagged: s.flagged));
    }
  }

  void next() {
    final s = state;
    if (s is QuizInProgress) goTo(s.index + 1);
  }

  void prev() {
    final s = state;
    if (s is QuizInProgress) goTo(s.index - 1);
  }

  /// Toggles "mark for review" for the current question.
  void toggleFlag() {
    final s = state;
    if (s is! QuizInProgress) return;
    final q = s.current;
    if (q == null) return;
    final next = Set<String>.from(s.flagged);
    next.contains(q.id) ? next.remove(q.id) : next.add(q.id);
    emit(QuizInProgress(
        attempt: s.attempt, index: s.index, answers: s.answers, flagged: next));
  }

  Future<void> submit() async {
    final s = state;
    if (s is! QuizInProgress) return;
    emit(QuizSubmitting(
        attempt: s.attempt, index: s.index, answers: s.answers, flagged: s.flagged));
    final r = await _repo.submit(s.attempt.attemptId);
    r.fold(
      (f) => emit(QuizInProgress(
          attempt: s.attempt, index: s.index, answers: s.answers, flagged: s.flagged)),
      (_) => emit(QuizSubmitted(
          attempt: s.attempt,
          index: s.index,
          answers: s.answers,
          flagged: s.flagged,
          attemptId: s.attempt.attemptId)),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz result
// ---------------------------------------------------------------------------
class QuizResultState extends Equatable {
  const QuizResultState({this.status = Load.initial, this.result, this.error});
  final Load status;
  final QuizResult? result;
  final String? error;

  QuizResultState copyWith({Load? status, QuizResult? result, String? error}) =>
      QuizResultState(
          status: status ?? this.status,
          result: result ?? this.result,
          error: error);

  @override
  List<Object?> get props => [status, result, error];
}

class QuizResultCubit extends Cubit<QuizResultState> {
  QuizResultCubit(this._repo) : super(const QuizResultState());
  final QuizRepository _repo;

  Future<void> load(String attemptId) async {
    emit(state.copyWith(status: Load.loading));
    final r = await _repo.result(attemptId);
    r.fold(
      (f) => emit(state.copyWith(status: Load.error, error: f.message)),
      (res) => emit(state.copyWith(status: Load.loaded, result: res)),
    );
  }
}
