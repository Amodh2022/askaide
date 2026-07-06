import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class RelationsState extends Equatable {
  const RelationsState({
    this.schoolId,
    this.links = const [],
    this.loading = false,
    this.teacherFilter = '',
    this.classFilter = '',
    this.subjectFilter = '',
    this.sectionFilter = '',
  });

  final String? schoolId;
  final List<AdminLink> links;
  final bool loading;
  final String teacherFilter;
  final String classFilter;
  final String subjectFilter;
  final String sectionFilter;

  int get activeFilterCount => [teacherFilter, classFilter, subjectFilter, sectionFilter]
      .where((f) => f.isNotEmpty)
      .length;

  List<AdminLink> get filtered => links
      .where((l) =>
          (teacherFilter.isEmpty || l.teacherName == teacherFilter) &&
          (classFilter.isEmpty || l.className == classFilter) &&
          (subjectFilter.isEmpty || l.subjectName == subjectFilter) &&
          (sectionFilter.isEmpty || l.sectionName == sectionFilter))
      .toList();

  RelationsState copyWith({
    String? schoolId,
    List<AdminLink>? links,
    bool? loading,
    String? teacherFilter,
    String? classFilter,
    String? subjectFilter,
    String? sectionFilter,
  }) =>
      RelationsState(
        schoolId: schoolId ?? this.schoolId,
        links: links ?? this.links,
        loading: loading ?? this.loading,
        teacherFilter: teacherFilter ?? this.teacherFilter,
        classFilter: classFilter ?? this.classFilter,
        subjectFilter: subjectFilter ?? this.subjectFilter,
        sectionFilter: sectionFilter ?? this.sectionFilter,
      );

  @override
  List<Object?> get props => [
        schoolId,
        links,
        loading,
        teacherFilter,
        classFilter,
        subjectFilter,
        sectionFilter,
      ];
}

/// Owns the admin Relations panel: selected school, loaded teacher↔student
/// links, and the committed filter set (teacher/class/subject/section).
class RelationsCubit extends Cubit<RelationsState> {
  RelationsCubit(this._repo) : super(const RelationsState());
  final AdminRepository _repo;

  List<String> uniq(String Function(AdminLink) sel) =>
      ({for (final l in state.links) if (sel(l).isNotEmpty) sel(l)}.toList()..sort());

  Future<void> load(String schoolId) async {
    emit(RelationsState(schoolId: schoolId, loading: true));
    final r = await _repo.teacherStudentLinksDetailed(schoolId);
    if (isClosed) return;
    emit(state.copyWith(loading: false, links: r.getOrElse(() => const [])));
  }

  void applyFilters({
    required String teacherFilter,
    required String classFilter,
    required String subjectFilter,
    required String sectionFilter,
  }) =>
      emit(state.copyWith(
        teacherFilter: teacherFilter,
        classFilter: classFilter,
        subjectFilter: subjectFilter,
        sectionFilter: sectionFilter,
      ));
}
