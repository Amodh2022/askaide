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
class QuizAttemptState extends Equatable {
  const QuizAttemptState({
    this.status = Load.initial,
    this.attempt,
    this.index = 0,
    this.answers = const {},
    this.flagged = const {},
    this.submitting = false,
    this.submittedAttemptId,
    this.error,
  });

  final Load status;
  final QuizAttempt? attempt;
  final int index;
  final Map<String, String> answers; // quizQuestionId -> selectedAnswer
  final Set<String> flagged; // quizQuestionIds marked for review
  final bool submitting;
  final String? submittedAttemptId; // set once submission succeeds
  final String? error;

  QuizQuestion? get current =>
      attempt != null && index >= 0 && index < attempt!.questions.length
          ? attempt!.questions[index]
          : null;
  int get total => attempt?.questions.length ?? 0;
  int get answeredCount => answers.length;
  int get flaggedCount => flagged.length;

  QuizAttemptState copyWith({
    Load? status,
    QuizAttempt? attempt,
    int? index,
    Map<String, String>? answers,
    Set<String>? flagged,
    bool? submitting,
    String? submittedAttemptId,
    String? error,
  }) =>
      QuizAttemptState(
        status: status ?? this.status,
        attempt: attempt ?? this.attempt,
        index: index ?? this.index,
        answers: answers ?? this.answers,
        flagged: flagged ?? this.flagged,
        submitting: submitting ?? this.submitting,
        submittedAttemptId: submittedAttemptId ?? this.submittedAttemptId,
        error: error,
      );

  @override
  List<Object?> get props => [
        status,
        attempt,
        index,
        answers,
        flagged,
        submitting,
        submittedAttemptId,
        error
      ];
}

class QuizAttemptCubit extends Cubit<QuizAttemptState> {
  QuizAttemptCubit(this._repo) : super(const QuizAttemptState());
  final QuizRepository _repo;

  /// When the current question was first shown — the anchor for the per-answer
  /// `timeSpent` we report, reset on every navigation (mirrors the frontend's
  /// `questionStartTime` ref).
  DateTime _questionEnteredAt = DateTime.now();

  /// Starts (or resumes) an attempt for a quiz. The `/start` endpoint is
  /// resume-or-create: for an in-progress attempt it returns the same attempt
  /// with its previously-saved answers, which we hydrate into [state.answers].
  Future<void> start(String quizId) async {
    emit(state.copyWith(status: Load.loading));
    final r = await _repo.start(quizId);
    r.fold(
      (f) => emit(state.copyWith(status: Load.error, error: f.message)),
      (a) => _onAttemptLoaded(a),
    );
  }

  /// Resumes / loads an existing attempt by id.
  Future<void> load(String attemptId) async {
    emit(state.copyWith(status: Load.loading));
    final r = await _repo.getAttempt(attemptId);
    r.fold(
      (f) => emit(state.copyWith(status: Load.error, error: f.message)),
      (a) => _onAttemptLoaded(a),
    );
  }

  /// Shared post-load: restore any previously-saved answers and reset the
  /// per-question timer (mirrors the frontend's `setAnswers(savedAnswers)`).
  void _onAttemptLoaded(QuizAttempt a) {
    _questionEnteredAt = DateTime.now();
    emit(state.copyWith(
      status: Load.loaded,
      attempt: a,
      answers: Map<String, String>.from(a.savedAnswers),
    ));
  }

  void select(String answer) {
    final q = state.current;
    if (q == null) return;
    final next = Map<String, String>.from(state.answers)..[q.id] = answer;
    emit(state.copyWith(answers: next));
    // Fire-and-forget per-question save (mirrors the frontend autosave),
    // reporting the seconds spent on this question since it was shown.
    final attemptId = state.attempt?.attemptId;
    if (attemptId != null) {
      final timeSpent = DateTime.now()
          .difference(_questionEnteredAt)
          .inSeconds
          .clamp(0, 1 << 31);
      _repo.answer(attemptId,
          quizQuestionId: q.id, selectedAnswer: answer, timeSpent: timeSpent);
    }
  }

  void goTo(int i) {
    if (i >= 0 && i < state.total) {
      _questionEnteredAt = DateTime.now();
      emit(state.copyWith(index: i));
    }
  }

  void next() => goTo(state.index + 1);
  void prev() => goTo(state.index - 1);

  /// Toggles "mark for review" for the current question.
  void toggleFlag() {
    final q = state.current;
    if (q == null) return;
    final next = Set<String>.from(state.flagged);
    next.contains(q.id) ? next.remove(q.id) : next.add(q.id);
    emit(state.copyWith(flagged: next));
  }

  Future<void> submit() async {
    final attemptId = state.attempt?.attemptId;
    if (attemptId == null) return;
    emit(state.copyWith(submitting: true));
    final r = await _repo.submit(attemptId);
    r.fold(
      (f) => emit(state.copyWith(submitting: false, error: f.message)),
      (_) => emit(
          state.copyWith(submitting: false, submittedAttemptId: attemptId)),
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
