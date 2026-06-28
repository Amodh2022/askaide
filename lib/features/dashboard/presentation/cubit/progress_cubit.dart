import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/progress_models.dart';
import '../../data/progress_repository.dart';

enum ProgressStatus { initial, loading, loaded, error, empty }

class ProgressState extends Equatable {
  const ProgressState({
    this.status = ProgressStatus.initial,
    this.classes = const [],
    this.selectedClassId,
    this.selectedSubjectId,
    this.data,
    this.selectedChapter,
    this.error,
  });

  final ProgressStatus status;
  final List<ClassConfig> classes;
  final String? selectedClassId;
  final String? selectedSubjectId;
  final SubjectProgressData? data;
  final ChapterProgress? selectedChapter;
  final String? error;

  List<SubjectOption> get subjects {
    final cls = classes.where((c) => c.id == selectedClassId);
    return cls.isEmpty ? const [] : cls.first.subjects;
  }

  /// Whether [chapterId] (within the selected subject) has questions ready and
  /// can be practised. The flag comes from `/study/configuration`; chapters not
  /// listed there are treated as not startable. Defaults to true when the
  /// configuration hasn't loaded so we don't wrongly block practice.
  bool isChapterStartable(String chapterId) {
    final subj = subjects.where((s) => s.id == selectedSubjectId);
    if (subj.isEmpty || subj.first.chapters.isEmpty) return true;
    final ch = subj.first.chapters.where((c) => c.id == chapterId);
    return ch.isEmpty ? false : ch.first.isStartable;
  }

  ProgressState copyWith({
    ProgressStatus? status,
    List<ClassConfig>? classes,
    String? selectedClassId,
    String? selectedSubjectId,
    SubjectProgressData? data,
    ChapterProgress? selectedChapter,
    bool clearChapter = false,
    bool clearData = false,
    String? error,
  }) =>
      ProgressState(
        status: status ?? this.status,
        classes: classes ?? this.classes,
        selectedClassId: selectedClassId ?? this.selectedClassId,
        selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
        data: clearData ? null : (data ?? this.data),
        selectedChapter:
            clearChapter ? null : (selectedChapter ?? this.selectedChapter),
        error: error,
      );

  @override
  List<Object?> get props => [
        status,
        classes,
        selectedClassId,
        selectedSubjectId,
        data,
        selectedChapter,
        error
      ];
}

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(this._repo) : super(const ProgressState());
  final ProgressRepository _repo;
  String _userId = '';

  Future<void> init(String userId) async {
    _userId = userId;
    if (userId.isEmpty) return;
    emit(state.copyWith(status: ProgressStatus.loading));
    final r = await _repo.configuration();
    r.fold(
      (f) =>
          emit(state.copyWith(status: ProgressStatus.empty, classes: const [])),
      (classes) {
        if (classes.isEmpty) {
          emit(state.copyWith(status: ProgressStatus.empty, classes: const []));
          return;
        }
        final first = classes.first;
        emit(state.copyWith(
          classes: classes,
          selectedClassId: first.id,
          selectedSubjectId:
              first.subjects.isNotEmpty ? first.subjects.first.id : null,
        ));
        if (first.subjects.isNotEmpty) {
          _loadProgress(first.subjects.first.id);
        } else {
          emit(state.copyWith(status: ProgressStatus.empty));
        }
      },
    );
  }

  void selectClass(String classId) {
    final cls = state.classes.where((c) => c.id == classId);
    final subjects = cls.isEmpty ? const <SubjectOption>[] : cls.first.subjects;
    final firstSubject = subjects.isNotEmpty ? subjects.first.id : null;
    emit(state.copyWith(
      selectedClassId: classId,
      selectedSubjectId: firstSubject,
      clearChapter: true,
      clearData: true,
    ));
    if (firstSubject != null) {
      _loadProgress(firstSubject);
    } else {
      emit(state.copyWith(status: ProgressStatus.empty));
    }
  }

  void selectSubject(String subjectId) {
    emit(state.copyWith(selectedSubjectId: subjectId, clearChapter: true));
    _loadProgress(subjectId);
  }

  Future<void> _loadProgress(String subjectId) async {
    if (_userId.isEmpty) return;
    emit(state.copyWith(
        status: ProgressStatus.loading, clearData: true, clearChapter: true));
    final r = await _repo.topicProgress(_userId, subjectId);
    r.fold(
      (f) => emit(state.copyWith(status: ProgressStatus.empty)),
      (data) => emit(state.copyWith(status: ProgressStatus.loaded, data: data)),
    );
  }

  void openChapter(ChapterProgress chapter) =>
      emit(state.copyWith(selectedChapter: chapter));
  void closeChapter() => emit(state.copyWith(clearChapter: true));

  /// Reloads the selected subject's topic progress in place (no loading flicker)
  /// and, if a chapter detail is open, re-selects the freshly-loaded version of
  /// it so its updated coverage/mastery shows. Used after a practice session
  /// launched from this page finishes. Keeps the current data on failure.
  Future<void> refreshSelectedSubject() async {
    final subjectId = state.selectedSubjectId;
    if (_userId.isEmpty || subjectId == null) return;
    final openChapterId = state.selectedChapter?.chapterId;
    final r = await _repo.topicProgress(_userId, subjectId);
    r.fold(
      (f) {}, // keep the current view on failure
      (data) {
        final match =
            data.chapters.where((ch) => ch.chapterId == openChapterId);
        final reopened = match.isEmpty ? null : match.first;
        emit(state.copyWith(
          status: ProgressStatus.loaded,
          data: data,
          selectedChapter: reopened,
          clearChapter: reopened == null,
        ));
      },
    );
  }
}
