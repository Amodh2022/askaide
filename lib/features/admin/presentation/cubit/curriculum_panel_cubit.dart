import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class CurriculumPanelState extends Equatable {
  const CurriculumPanelState({
    this.classId,
    this.subjectId,
    this.subjects = const [],
    this.items = const [],
    this.selected = const {},
    this.loading = false,
  });

  final String? classId;
  final String? subjectId;
  final List<AdminRecord> subjects;
  final List<AdminRecord> items;
  final Set<String> selected;
  final bool loading;

  CurriculumPanelState copyWith({
    String? subjectId,
    List<AdminRecord>? subjects,
    List<AdminRecord>? items,
    Set<String>? selected,
    bool? loading,
  }) =>
      CurriculumPanelState(
        classId: classId,
        subjectId: subjectId ?? this.subjectId,
        subjects: subjects ?? this.subjects,
        items: items ?? this.items,
        selected: selected ?? this.selected,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [classId, subjectId, subjects, items, selected, loading];
}

/// Owns the class/subject-scoped curriculum panel: cascading class→subject
/// selection, the loaded chapter/topic list, multi-select for bulk delete,
/// and chapter create/delete. Shared by the Chapters, Upload, and Topics
/// tabs (only chapter mutations are exposed; topics are read-only browse).
class CurriculumPanelCubit extends Cubit<CurriculumPanelState> {
  CurriculumPanelCubit(this._repo) : super(const CurriculumPanelState());
  final AdminRepository _repo;

  Future<void> loadSubjects(String classId) async {
    emit(CurriculumPanelState(classId: classId));
    final r = await _repo.subjects(classId);
    if (isClosed) return;
    emit(state.copyWith(subjects: r.getOrElse(() => const [])));
  }

  Future<void> loadItems(String subjectId, {required bool topics}) async {
    emit(state.copyWith(
        subjectId: subjectId, loading: true, items: const [], selected: const {}));
    final classId = state.classId!;
    final r = topics
        ? await _repo.topics(classId, subjectId)
        : await _repo.chapters(classId, subjectId);
    if (isClosed) return;
    emit(state.copyWith(loading: false, items: r.getOrElse(() => const [])));
  }

  void toggleSelectAll() {
    if (state.selected.length == state.items.length) {
      emit(state.copyWith(selected: const {}));
    } else {
      emit(state.copyWith(selected: state.items.map((e) => e.id).toSet()));
    }
  }

  void toggleItem(String id) {
    final next = Set<String>.from(state.selected);
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(selected: next));
  }

  Future<bool> addChapter(String name, int order) async {
    final classId = state.classId;
    final subjectId = state.subjectId;
    if (classId == null || subjectId == null) return false;
    final r = await _repo.createChapter(classId, subjectId, name, order);
    if (isClosed) return r.isRight();
    if (r.isRight()) await loadItems(subjectId, topics: false);
    return r.isRight();
  }

  Future<bool> deleteChapter(String id) async {
    final r = await _repo.deleteChapters(state.classId!, state.subjectId!, [id]);
    if (isClosed) return r.isRight();
    if (r.isRight()) await loadItems(state.subjectId!, topics: false);
    return r.isRight();
  }

  /// Bulk-deletes the checked chapters. Returns the deleted count on success,
  /// or null on failure.
  Future<int?> bulkDelete() async {
    final subjectId = state.subjectId!;
    final ids = state.selected.toList();
    final r = await _repo.deleteChapters(state.classId!, subjectId, ids);
    if (isClosed) return r.isRight() ? ids.length : null;
    if (r.isRight()) {
      emit(state.copyWith(selected: const {}));
      await loadItems(subjectId, topics: false);
    }
    return r.isRight() ? ids.length : null;
  }
}
