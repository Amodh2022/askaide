import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/taxonomy/taxonomy_repository.dart';
import '../data/quiz_models.dart';
import '../data/quiz_repository.dart';

enum TqLoad { initial, loading, loaded, error }

// ---- Teacher quiz list -----------------------------------------------------
class TeacherQuizListState extends Equatable {
  const TeacherQuizListState({this.status = TqLoad.initial, this.quizzes = const [], this.error});
  final TqLoad status;
  final List<TeacherQuiz> quizzes;
  final String? error;

  TeacherQuizListState copyWith({TqLoad? status, List<TeacherQuiz>? quizzes, String? error}) =>
      TeacherQuizListState(
          status: status ?? this.status, quizzes: quizzes ?? this.quizzes, error: error);

  @override
  List<Object?> get props => [status, quizzes, error];
}

class TeacherQuizListCubit extends Cubit<TeacherQuizListState> {
  TeacherQuizListCubit(this._repo) : super(const TeacherQuizListState());
  final QuizRepository _repo;
  String _teacherId = '';

  Future<void> load(String teacherId) async {
    _teacherId = teacherId;
    emit(state.copyWith(status: TqLoad.loading));
    final r = await _repo.teacherQuizzes(teacherId);
    r.fold(
      (f) => emit(state.copyWith(status: TqLoad.error, error: f.message)),
      (list) => emit(state.copyWith(status: TqLoad.loaded, quizzes: list)),
    );
  }

  Future<void> publish(String id) async { await _repo.publishQuiz(id); await load(_teacherId); }
  Future<void> closeQuiz(String id) async { await _repo.closeQuiz(id); await load(_teacherId); }
  Future<void> clone(String id) async { await _repo.cloneQuiz(id); await load(_teacherId); }
  Future<void> remove(String id) async { await _repo.deleteQuiz(id, force: true); await load(_teacherId); }
}

// ---- Quiz builder (create + add questions) --------------------------------
class QuizBuilderState extends Equatable {
  const QuizBuilderState({
    this.classes = const [],
    this.subjects = const [],
    this.chapters = const [],
    this.classId,
    this.subjectId,
    this.chapterIds = const {},
    this.bank = const [],
    this.selectedQuestionIds = const {},
    this.selectedOrder = const [],
    this.marksById = const {},
    this.managed = const [],
    this.loadingManaged = false,
    this.creating = false,
    this.createdQuizId,
    this.searching = false,
    this.error,
  });

  final List<TaxItem> classes;
  final List<TaxItem> subjects;
  final List<TaxItem> chapters;
  final String? classId;
  final String? subjectId;
  final Set<String> chapterIds;
  final List<BankQuestion> bank;
  final Set<String> selectedQuestionIds;

  /// Selected question ids in display order (drives reorder + add order).
  final List<String> selectedOrder;

  /// Per-question marks for selected questions (defaults to 1 when absent).
  final Map<String, int> marksById;

  /// Questions already attached to the quiz (teacher manager view), in order.
  final List<QuizManagedQuestion> managed;
  final bool loadingManaged;
  final bool creating;
  final String? createdQuizId;
  final bool searching;
  final String? error;

  QuizBuilderState copyWith({
    List<TaxItem>? classes,
    List<TaxItem>? subjects,
    List<TaxItem>? chapters,
    String? classId,
    String? subjectId,
    Set<String>? chapterIds,
    List<BankQuestion>? bank,
    Set<String>? selectedQuestionIds,
    List<String>? selectedOrder,
    Map<String, int>? marksById,
    List<QuizManagedQuestion>? managed,
    bool? loadingManaged,
    bool? creating,
    String? createdQuizId,
    bool? searching,
    String? error,
    bool clearSubject = false,
    bool clearChapters = false,
  }) =>
      QuizBuilderState(
        classes: classes ?? this.classes,
        subjects: subjects ?? this.subjects,
        chapters: chapters ?? this.chapters,
        classId: classId ?? this.classId,
        subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
        chapterIds: clearChapters ? const {} : (chapterIds ?? this.chapterIds),
        bank: bank ?? this.bank,
        selectedQuestionIds: selectedQuestionIds ?? this.selectedQuestionIds,
        selectedOrder: selectedOrder ?? this.selectedOrder,
        marksById: marksById ?? this.marksById,
        managed: managed ?? this.managed,
        loadingManaged: loadingManaged ?? this.loadingManaged,
        creating: creating ?? this.creating,
        createdQuizId: createdQuizId,
        searching: searching ?? this.searching,
        error: error,
      );

  @override
  List<Object?> get props => [
        classes, subjects, chapters, classId, subjectId, chapterIds,
        bank, selectedQuestionIds, selectedOrder, marksById, managed, loadingManaged,
        creating, createdQuizId, searching, error,
      ];
}

class QuizBuilderCubit extends Cubit<QuizBuilderState> {
  QuizBuilderCubit(this._repo, this._tax) : super(const QuizBuilderState());
  final QuizRepository _repo;
  final TaxonomyRepository _tax;

  Future<void> init() async {
    final r = await _tax.classes();
    emit(state.copyWith(classes: r.getOrElse(() => const [])));
  }

  Future<void> selectClass(String id) async {
    emit(state.copyWith(classId: id, subjects: const [], chapters: const [], clearSubject: true, clearChapters: true));
    final r = await _tax.subjects(id);
    emit(state.copyWith(subjects: r.getOrElse(() => const [])));
  }

  Future<void> selectSubject(String id) async {
    final classId = state.classId;
    if (classId == null) return;
    emit(state.copyWith(subjectId: id, chapters: const [], clearChapters: true));
    final r = await _tax.chapters(classId, id);
    emit(state.copyWith(chapters: r.getOrElse(() => const [])));
  }

  void toggleChapter(String id) {
    final next = Set<String>.from(state.chapterIds);
    if (!next.add(id)) next.remove(id);
    emit(state.copyWith(chapterIds: next));
  }

  void toggleQuestion(String id) {
    final next = Set<String>.from(state.selectedQuestionIds);
    final order = List<String>.from(state.selectedOrder);
    if (next.add(id)) {
      order.add(id);
    } else {
      next.remove(id);
      order.remove(id);
    }
    emit(state.copyWith(selectedQuestionIds: next, selectedOrder: order));
  }

  /// Sets the marks for a selected question (used by the per-question input).
  void setMarks(String id, int marks) {
    final next = Map<String, int>.from(state.marksById);
    next[id] = marks < 1 ? 1 : marks;
    emit(state.copyWith(marksById: next));
  }

  /// Reorders the already-selected (to-be-added) questions. Uses the
  /// `onReorderItem` convention where [newIndex] is already adjusted for the
  /// item removed at [oldIndex].
  void reorderSelected(int oldIndex, int newIndex) {
    final order = List<String>.from(state.selectedOrder);
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    emit(state.copyWith(selectedOrder: order));
  }

  Future<void> create(String title, String description, QuizSettingsDraft settings) async {
    if (state.classId == null || state.subjectId == null) return;
    emit(state.copyWith(creating: true, error: null));
    final r = await _repo.createQuiz({
      'title': title,
      'description': description,
      'classId': state.classId,
      'subjectId': state.subjectId,
      'chapterIds': state.chapterIds.toList(),
      'settings': settings.toJson(),
    });
    r.fold(
      (f) => emit(state.copyWith(creating: false, error: f.message)),
      (id) => emit(state.copyWith(creating: false, createdQuizId: id)),
    );
  }

  Future<void> search() async {
    if (state.classId == null || state.subjectId == null || state.chapterIds.isEmpty) return;
    emit(state.copyWith(searching: true));
    final r = await _repo.searchBank(
      classId: state.classId!,
      subjectId: state.subjectId!,
      chapterIds: state.chapterIds.toList(),
    );
    emit(state.copyWith(searching: false, bank: r.getOrElse(() => const [])));
  }

  /// Loads the questions already attached to [quizId] (teacher manager view).
  Future<void> loadQuiz(String quizId) async {
    emit(state.copyWith(loadingManaged: true));
    final r = await _repo.quizQuestions(quizId);
    emit(state.copyWith(
      loadingManaged: false,
      managed: r.getOrElse(() => const []),
    ));
  }

  /// Reorders the quiz's attached questions, then persists via the backend
  /// reorder endpoint. Uses the `onReorderItem` convention where [newIndex] is
  /// already adjusted for the item removed at [oldIndex].
  Future<void> reorderManaged(String quizId, int oldIndex, int newIndex) async {
    final list = List<QuizManagedQuestion>.from(state.managed);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    emit(state.copyWith(managed: list)); // optimistic
    await _repo.reorderQuestions(quizId, [for (final q in list) q.id]);
  }

  /// Removes an attached question, then refreshes the managed list.
  Future<void> removeManaged(String quizId, String questionId) async {
    final r = await _repo.removeQuestion(quizId, questionId);
    if (r.isLeft()) return;
    await loadQuiz(quizId);
  }

  Future<bool> addSelectedTo(String quizId) async {
    if (state.selectedOrder.isEmpty) return false;
    final r = await _repo.addQuestions(
      quizId,
      state.selectedOrder,
      marksById: state.marksById,
    );
    if (r.isLeft()) return false;
    // Persist the chosen order on the backend (matches React drag-reorder).
    if (state.selectedOrder.length > 1) {
      await _repo.reorderQuestions(quizId, state.selectedOrder);
    }
    // Clear the bank selection and refresh the attached-question list so newly
    // added questions appear immediately (mirrors React's fetchQuiz refresh).
    emit(state.copyWith(
      selectedQuestionIds: const {},
      selectedOrder: const [],
      marksById: const {},
    ));
    await loadQuiz(quizId);
    return true;
  }
}

/// The advanced quiz settings configured on the create form. Keys mirror
/// React's `DEFAULT_SETTINGS`/create payload in QuizForm.jsx exactly.
class QuizSettingsDraft extends Equatable {
  const QuizSettingsDraft({
    this.timeLimit,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
    this.showAnswersAfter = 'submission',
    this.allowedAttempts = 1,
    this.passingPercentage = 50,
    this.deadline,
  });

  final int? timeLimit; // minutes; null = no limit
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final String showAnswersAfter; // immediately | submission | deadline | never
  final int allowedAttempts;
  final int passingPercentage;
  final DateTime? deadline;

  QuizSettingsDraft copyWith({
    int? timeLimit,
    bool clearTimeLimit = false,
    bool? shuffleQuestions,
    bool? shuffleOptions,
    String? showAnswersAfter,
    int? allowedAttempts,
    int? passingPercentage,
    DateTime? deadline,
    bool clearDeadline = false,
  }) =>
      QuizSettingsDraft(
        timeLimit: clearTimeLimit ? null : (timeLimit ?? this.timeLimit),
        shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
        shuffleOptions: shuffleOptions ?? this.shuffleOptions,
        showAnswersAfter: showAnswersAfter ?? this.showAnswersAfter,
        allowedAttempts: allowedAttempts ?? this.allowedAttempts,
        passingPercentage: passingPercentage ?? this.passingPercentage,
        deadline: clearDeadline ? null : (deadline ?? this.deadline),
      );

  Map<String, dynamic> toJson() => {
        'timeLimit': timeLimit,
        'shuffleQuestions': shuffleQuestions,
        'shuffleOptions': shuffleOptions,
        'showAnswersAfter': showAnswersAfter,
        'allowedAttempts': allowedAttempts,
        'passingPercentage': passingPercentage,
        'deadline': deadline?.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => [
        timeLimit,
        shuffleQuestions,
        shuffleOptions,
        showAnswersAfter,
        allowedAttempts,
        passingPercentage,
        deadline,
      ];
}

// ---- Quiz analytics --------------------------------------------------------
class QuizAnalyticsState extends Equatable {
  const QuizAnalyticsState({this.status = TqLoad.initial, this.data = const QuizAnalyticsData()});
  final TqLoad status;
  final QuizAnalyticsData data;

  QuizAnalyticsState copyWith({TqLoad? status, QuizAnalyticsData? data}) =>
      QuizAnalyticsState(status: status ?? this.status, data: data ?? this.data);

  @override
  List<Object?> get props => [status, data];
}

class QuizAnalyticsCubit extends Cubit<QuizAnalyticsState> {
  QuizAnalyticsCubit(this._repo) : super(const QuizAnalyticsState());
  final QuizRepository _repo;

  Future<void> load(String quizId) async {
    emit(state.copyWith(status: TqLoad.loading));
    final r = await _repo.analytics(quizId);
    r.fold(
      (f) => emit(state.copyWith(status: TqLoad.error)),
      (d) => emit(state.copyWith(status: TqLoad.loaded, data: d)),
    );
  }
}
