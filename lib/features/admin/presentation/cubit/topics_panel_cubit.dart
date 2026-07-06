import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class TopicsPanelState extends Equatable {
  const TopicsPanelState({
    this.classId,
    this.subjectId,
    this.subjects = const [],
    this.topics = const [],
    this.loading = false,
    this.search = '',
  });

  final String? classId;
  final String? subjectId;
  final List<AdminRecord> subjects;
  final List<AdminRecord> topics;
  final bool loading;
  final String search;

  TopicsPanelState copyWith({
    String? subjectId,
    List<AdminRecord>? subjects,
    List<AdminRecord>? topics,
    bool? loading,
    String? search,
  }) =>
      TopicsPanelState(
        classId: classId,
        subjectId: subjectId ?? this.subjectId,
        subjects: subjects ?? this.subjects,
        topics: topics ?? this.topics,
        loading: loading ?? this.loading,
        search: search ?? this.search,
      );

  @override
  List<Object?> get props => [classId, subjectId, subjects, topics, loading, search];
}

/// Owns the Topics browser's cascading class→subject selection, the loaded
/// (read-only) topic list, and the local name-search filter.
class TopicsPanelCubit extends Cubit<TopicsPanelState> {
  TopicsPanelCubit(this._repo)
      : searchController = TextEditingController(),
        super(const TopicsPanelState());

  final AdminRepository _repo;
  final TextEditingController searchController;

  Future<void> loadSubjects(String classId) async {
    emit(TopicsPanelState(classId: classId));
    searchController.clear();
    final r = await _repo.subjects(classId);
    if (isClosed) return;
    emit(state.copyWith(subjects: r.getOrElse(() => const [])));
  }

  Future<void> loadTopics(String subjectId) async {
    emit(state.copyWith(subjectId: subjectId, loading: true, topics: const [], search: ''));
    searchController.clear();
    final r = await _repo.topics(state.classId!, subjectId);
    if (isClosed) return;
    emit(state.copyWith(loading: false, topics: r.getOrElse(() => const [])));
  }

  void setSearch(String value) => emit(state.copyWith(search: value));

  void clearSearch() {
    searchController.clear();
    emit(state.copyWith(search: ''));
  }

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
