import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class ChaptersPanelState extends Equatable {
  const ChaptersPanelState({
    this.classId,
    this.subjectId,
    this.subjects = const [],
    this.chapters = const [],
    this.selected = const {},
    this.loading = false,
    this.formOpen = false,
    this.creating = false,
    this.deletingId,
    this.bulkDeleting = false,
    this.search = '',
  });

  final String? classId;
  final String? subjectId;
  final List<AdminRecord> subjects;
  final List<AdminRecord> chapters;
  final Set<String> selected;
  final bool loading;
  final bool formOpen;
  final bool creating;
  final String? deletingId;
  final bool bulkDeleting;
  final String search;

  ChaptersPanelState copyWith({
    String? subjectId,
    List<AdminRecord>? subjects,
    List<AdminRecord>? chapters,
    Set<String>? selected,
    bool? loading,
    bool? formOpen,
    bool? creating,
    String? deletingId,
    bool? bulkDeleting,
    String? search,
    bool clearDeletingId = false,
  }) =>
      ChaptersPanelState(
        classId: classId,
        subjectId: subjectId ?? this.subjectId,
        subjects: subjects ?? this.subjects,
        chapters: chapters ?? this.chapters,
        selected: selected ?? this.selected,
        loading: loading ?? this.loading,
        formOpen: formOpen ?? this.formOpen,
        creating: creating ?? this.creating,
        deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
        bulkDeleting: bulkDeleting ?? this.bulkDeleting,
        search: search ?? this.search,
      );

  @override
  List<Object?> get props => [
        classId,
        subjectId,
        subjects,
        chapters,
        selected,
        loading,
        formOpen,
        creating,
        deletingId,
        bulkDeleting,
        search,
      ];
}

/// Owns the Chapters panel: cascading class→subject selection, the loaded
/// chapter list, the create-chapter form, multi-select + bulk delete, the
/// per-row delete-in-progress id, and the local name-search filter.
class ChaptersPanelCubit extends Cubit<ChaptersPanelState> {
  ChaptersPanelCubit(this._repo)
      : formKey = GlobalKey<FormState>(),
        nameController = TextEditingController(),
        orderController = TextEditingController(),
        searchController = TextEditingController(),
        super(const ChaptersPanelState());

  final AdminRepository _repo;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController orderController;
  final TextEditingController searchController;

  Future<void> loadSubjects(String classId) async {
    emit(ChaptersPanelState(classId: classId));
    searchController.clear();
    final r = await _repo.subjects(classId);
    if (isClosed) return;
    emit(state.copyWith(subjects: r.getOrElse(() => const [])));
  }

  Future<void> loadChapters(String subjectId) async {
    emit(state.copyWith(
        subjectId: subjectId, loading: true, chapters: const [], selected: const {}, search: ''));
    searchController.clear();
    final r = await _repo.chapters(state.classId!, subjectId);
    if (isClosed) return;
    emit(state.copyWith(loading: false, chapters: r.getOrElse(() => const [])));
  }

  void openForm() => emit(state.copyWith(formOpen: true));

  void closeForm() {
    nameController.clear();
    orderController.clear();
    emit(state.copyWith(formOpen: false));
  }

  /// Returns false (and does nothing else) if the name field is empty so the
  /// caller can show a validation snackbar.
  Future<bool> create() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return false;
    emit(state.copyWith(creating: true));
    final r = await _repo.createChapter(
        state.classId!, state.subjectId!, name, int.tryParse(orderController.text.trim()) ?? 0);
    if (isClosed) return r.isRight();
    emit(state.copyWith(creating: false));
    if (r.isRight()) {
      nameController.clear();
      orderController.clear();
      emit(state.copyWith(formOpen: false));
      await loadChapters(state.subjectId!);
    }
    return r.isRight();
  }

  Future<bool> delete(String id) async {
    emit(state.copyWith(deletingId: id));
    final r = await _repo.deleteChapters(state.classId!, state.subjectId!, [id]);
    if (isClosed) return r.isRight();
    emit(state.copyWith(clearDeletingId: true));
    if (r.isRight()) await loadChapters(state.subjectId!);
    return r.isRight();
  }

  void toggleSelectAll(List<String> visibleIds) {
    final visibleSet = visibleIds.toSet();
    final next = Set<String>.from(state.selected);
    if (visibleSet.every(next.contains)) {
      next.removeAll(visibleSet);
    } else {
      next.addAll(visibleSet);
    }
    emit(state.copyWith(selected: next));
  }

  void toggleItem(String id) {
    final next = Set<String>.from(state.selected);
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(selected: next));
  }

  void clearSelection() => emit(state.copyWith(selected: const {}));

  /// Returns the deleted count on success, or null on failure.
  Future<int?> bulkDelete() async {
    final ids = state.selected.toList();
    emit(state.copyWith(bulkDeleting: true));
    final r = await _repo.deleteChapters(state.classId!, state.subjectId!, ids);
    if (isClosed) return r.isRight() ? ids.length : null;
    emit(state.copyWith(bulkDeleting: false));
    if (r.isRight()) {
      emit(state.copyWith(selected: const {}));
      await loadChapters(state.subjectId!);
    }
    return r.isRight() ? ids.length : null;
  }

  void setSearch(String value) => emit(state.copyWith(search: value));

  @override
  Future<void> close() {
    nameController.dispose();
    orderController.dispose();
    searchController.dispose();
    return super.close();
  }
}
