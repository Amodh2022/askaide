import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class AdminOverviewState extends Equatable {
  AdminOverviewState({
    DateTimeRange? range,
    this.classId,
    this.subjectId,
    this.subjects = const [],
    this.overview,
    this.users,
    this.content,
    this.jobs,
    this.engagement,
    this.loading = true,
    this.error = false,
    this.updatedAt,
  }) : range = range ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 29)),
              end: DateTime.now(),
            );

  final DateTimeRange range;
  final String? classId;
  final String? subjectId;
  final List<AdminRecord> subjects;
  final Map<String, dynamic>? overview;
  final Map<String, dynamic>? users;
  final Map<String, dynamic>? content;
  final Map<String, dynamic>? jobs;
  final Map<String, dynamic>? engagement;
  final bool loading;
  final bool error;
  final TimeOfDay? updatedAt;

  AdminOverviewState copyWith({
    DateTimeRange? range,
    String? classId,
    String? subjectId,
    List<AdminRecord>? subjects,
    Map<String, dynamic>? overview,
    Map<String, dynamic>? users,
    Map<String, dynamic>? content,
    Map<String, dynamic>? jobs,
    Map<String, dynamic>? engagement,
    bool? loading,
    bool? error,
    TimeOfDay? updatedAt,
    bool clearClassId = false,
    bool clearSubjectId = false,
  }) =>
      AdminOverviewState(
        range: range ?? this.range,
        classId: clearClassId ? null : (classId ?? this.classId),
        subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
        subjects: subjects ?? this.subjects,
        overview: overview ?? this.overview,
        users: users ?? this.users,
        content: content ?? this.content,
        jobs: jobs ?? this.jobs,
        engagement: engagement ?? this.engagement,
        loading: loading ?? this.loading,
        error: error ?? this.error,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        range, classId, subjectId, subjects, overview, users, content, jobs,
        engagement, loading, error, updatedAt,
      ];
}

/// Owns the SuperAdmin overview dashboard: date-range + class/subject
/// filters, and the five parallel metrics fetches they drive.
class AdminOverviewCubit extends Cubit<AdminOverviewState> {
  AdminOverviewCubit(this._repo) : super(AdminOverviewState());

  final AdminRepository _repo;

  static String fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: false));
    final from = fmtDate(state.range.start);
    final to = fmtDate(state.range.end);
    final results = await Future.wait([
      _repo.overviewMetrics(),
      _repo.userMetrics(from: from, to: to),
      _repo.contentMetrics(classId: state.classId, subjectId: state.subjectId),
      _repo.questionJobMetrics(),
      _repo.engagementMetrics(
          from: from, to: to, classId: state.classId, subjectId: state.subjectId),
    ]);
    if (isClosed) return;
    final maps =
        results.map((r) => r.fold<Map<String, dynamic>?>((_) => null, (m) => m)).toList();
    emit(state.copyWith(
      loading: false,
      error: results.every((r) => r.isLeft()),
      overview: maps[0],
      users: maps[1],
      content: maps[2],
      jobs: maps[3],
      engagement: maps[4],
      updatedAt: TimeOfDay.now(),
    ));
  }

  Future<void> selectClass(String? classId) async {
    emit(state.copyWith(
      classId: classId,
      clearClassId: classId == null,
      subjects: const [],
      clearSubjectId: true,
    ));
    if (classId != null) {
      final r = await _repo.subjects(classId);
      if (isClosed) return;
      emit(state.copyWith(subjects: r.getOrElse(() => const [])));
    }
    await load();
  }

  void selectSubject(String? subjectId) {
    emit(state.copyWith(subjectId: subjectId, clearSubjectId: subjectId == null));
    load();
  }

  void quickRange(int days) {
    final now = DateTime.now();
    emit(state.copyWith(
        range: DateTimeRange(start: now.subtract(Duration(days: days - 1)), end: now)));
    load();
  }

  void setRange(DateTimeRange range) {
    emit(state.copyWith(range: range));
    load();
  }
}
