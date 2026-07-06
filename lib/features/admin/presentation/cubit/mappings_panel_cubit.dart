import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_feature.dart';

class MappingsPanelState extends Equatable {
  const MappingsPanelState({
    this.teacherId,
    this.classId,
    this.sectionId,
    this.subjectId,
    this.studentIds = const {},
    this.subjects = const [],
    this.classSections = const [],
    this.saving = false,
  });

  final String? teacherId;
  final String? classId;
  final String? sectionId;
  final String? subjectId;
  final Set<String> studentIds;
  final List<AdminRecord> subjects;
  final List<AdminRecord> classSections;
  final bool saving;

  MappingsPanelState copyWith({
    String? teacherId,
    String? classId,
    String? sectionId,
    String? subjectId,
    Set<String>? studentIds,
    List<AdminRecord>? subjects,
    List<AdminRecord>? classSections,
    bool? saving,
    bool clearSectionId = false,
    bool clearSubjectId = false,
  }) =>
      MappingsPanelState(
        teacherId: teacherId ?? this.teacherId,
        classId: classId ?? this.classId,
        sectionId: clearSectionId ? null : (sectionId ?? this.sectionId),
        subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
        studentIds: studentIds ?? this.studentIds,
        subjects: subjects ?? this.subjects,
        classSections: classSections ?? this.classSections,
        saving: saving ?? this.saving,
      );

  @override
  List<Object?> get props => [
        teacherId,
        classId,
        sectionId,
        subjectId,
        studentIds,
        subjects,
        classSections,
        saving,
      ];
}

/// Owns the teacher→student mapping form: teacher/class/section/subject
/// selection, the class's cascading subjects + sections, the checked student
/// set, and the link-creation submit flow.
class MappingsPanelCubit extends Cubit<MappingsPanelState> {
  MappingsPanelCubit(this._repo) : super(const MappingsPanelState());
  final AdminRepository _repo;

  /// Called when the global school selector changes — the form is scoped to
  /// one school at a time, so everything downstream resets.
  void resetForSchoolChange() => emit(const MappingsPanelState());

  void setTeacher(String id) => emit(state.copyWith(teacherId: id));

  Future<void> selectClass(String classId, String? schoolId) async {
    emit(state.copyWith(
      classId: classId,
      clearSectionId: true,
      clearSubjectId: true,
      subjects: const [],
      classSections: const [],
    ));
    final sub = await _repo.subjects(classId);
    if (isClosed) return;
    emit(state.copyWith(subjects: sub.getOrElse(() => const [])));
    if (schoolId != null) {
      final sec = await _repo.sectionsByClass(schoolId, classId);
      if (isClosed) return;
      emit(state.copyWith(classSections: sec.getOrElse(() => const [])));
    }
  }

  void setSection(String? id) =>
      emit(state.copyWith(sectionId: id, clearSectionId: id == null));

  void setSubject(String id) => emit(state.copyWith(subjectId: id));

  void toggleStudent(String id) {
    final next = Set<String>.from(state.studentIds);
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(studentIds: next));
  }

  void toggleSelectAll(List<String> allIds) {
    if (state.studentIds.length == allIds.length) {
      emit(state.copyWith(studentIds: const {}));
    } else {
      emit(state.copyWith(studentIds: allIds.toSet()));
    }
  }

  Future<bool> submit(String schoolId) async {
    if (state.teacherId == null ||
        state.classId == null ||
        state.subjectId == null ||
        state.studentIds.isEmpty) {
      return false;
    }
    emit(state.copyWith(saving: true));
    final r = await _repo.createTeacherStudentLink(
      schoolId: schoolId,
      teacherId: state.teacherId!,
      studentIds: state.studentIds.toList(),
      sectionId: state.sectionId,
      classId: state.classId,
      subjectId: state.subjectId,
    );
    if (isClosed) return r.isRight();
    emit(state.copyWith(
      saving: false,
      studentIds: r.isRight() ? const {} : state.studentIds,
    ));
    return r.isRight();
  }
}
