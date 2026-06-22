import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/api_helpers.dart';
import '../../../core/network/endpoints.dart';

/// A generic named record used across admin tables (school/class/section).
class AdminRecord extends Equatable {
  const AdminRecord({required this.id, required this.name, this.subtitle = ''});
  final String id;
  final String name;
  final String subtitle;

  factory AdminRecord.school(Map<dynamic, dynamic> j) => AdminRecord(
        id: j.str(['_id', 'id']),
        name: j.str(['name', 'schoolName'], 'School'),
        subtitle: j.str(['address', 'city']),
      );

  factory AdminRecord.person(Map<dynamic, dynamic> j) => AdminRecord(
        id: j.str(['_id', 'id']),
        name: [j.str(['firstName']), j.str(['lastName'])].where((s) => s.isNotEmpty).join(' ').trim().isEmpty
            ? j.str(['name'], 'User')
            : [j.str(['firstName']), j.str(['lastName'])].where((s) => s.isNotEmpty).join(' '),
        subtitle: j.str(['email']),
      );

  factory AdminRecord.named(Map<dynamic, dynamic> j) => AdminRecord(
        id: j.str(['_id', 'id']),
        name: j.str(['name', 'topicName', 'chapterName'], 'Item'),
      );

  factory AdminRecord.chapter(Map<dynamic, dynamic> j) {
    final order = j.intval(['order']);
    return AdminRecord(
      id: j.str(['_id', 'id']),
      name: j.str(['name', 'chapterName'], 'Chapter'),
      subtitle: order > 0 ? 'Chapter $order' : '',
    );
  }

  factory AdminRecord.link(Map<dynamic, dynamic> j) {
    final teacher = j['teacher'] is Map ? j['teacher'] as Map : const {};
    final student = j['student'] is Map ? j['student'] as Map : const {};
    String nameOf(Map m, String fallback) {
      final n = [m.str(['firstName']), m.str(['lastName'])].where((s) => s.isNotEmpty).join(' ');
      return n.isEmpty ? m.str(['name', 'email'], fallback) : n;
    }
    return AdminRecord(
      id: j.str(['_id', 'id']),
      name: teacher.isEmpty ? j.str(['teacherName'], 'Teacher') : nameOf(teacher, 'Teacher'),
      subtitle: '→ ${student.isEmpty ? j.str(['studentName'], 'Student') : nameOf(student, 'Student')}',
    );
  }

  @override
  List<Object?> get props => [id, name, subtitle];
}

class AdminRepository {
  AdminRepository(this._dio);
  final Dio _dio;

  Future<Either<Failure, List<AdminRecord>>> schools() => guardEither(() async {
        final res = await _dio.get(Endpoints.school);
        return res.dataList().whereType<Map>().map(AdminRecord.school).toList();
      });

  Future<Either<Failure, List<AdminRecord>>> classes() => guardEither(() async {
        final res = await _dio.get(Endpoints.classes);
        return res.dataList().whereType<Map>().map(AdminRecord.named).toList();
      });

  Future<Either<Failure, List<AdminRecord>>> teachers(String schoolId) =>
      guardEither(() async {
        final res = await _dio
            .get(Endpoints.teacherGetAll, queryParameters: {'schoolId': schoolId});
        return res.dataList().whereType<Map>().map(AdminRecord.person).toList();
      });

  Future<Either<Failure, List<AdminRecord>>> students(String schoolId) =>
      guardEither(() async {
        final res = await _dio
            .get(Endpoints.studentGetAll, queryParameters: {'schoolId': schoolId});
        return res.dataList().whereType<Map>().map(AdminRecord.person).toList();
      });

  Future<Either<Failure, Unit>> createSchool(String name, String address) =>
      guardEither(() async {
        await _dio.post(Endpoints.school, data: {'name': name, 'address': address});
        return unit;
      });

  Future<Either<Failure, Unit>> createTeacher(
          String firstName, String lastName, String email, String schoolId) =>
      guardEither(() async {
        await _dio.post(Endpoints.teacher, data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'schoolId': schoolId,
        });
        return unit;
      });

  Future<Either<Failure, Unit>> createStudent(
          String firstName, String lastName, String email, String schoolId) =>
      guardEither(() async {
        await _dio.post(Endpoints.studentCreate, data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'schoolId': schoolId,
        });
        return unit;
      });

  Future<Either<Failure, List<AdminRecord>>> sections(String schoolId) =>
      guardEither(() async {
        final res = await _dio.get('/sections/school/$schoolId');
        return res.dataList().whereType<Map>().map(AdminRecord.named).toList();
      });

  Future<Either<Failure, Unit>> createSection(String name, String schoolId) =>
      guardEither(() async {
        await _dio.post('/sections', data: {'name': name, 'schoolId': schoolId});
        return unit;
      });

  Future<Either<Failure, Unit>> deleteSection(String id) =>
      guardEither(() async { await _dio.delete('/sections/$id'); return unit; });

  Future<Either<Failure, Unit>> deleteTeacher(String id) =>
      guardEither(() async { await _dio.delete('/teacher/$id'); return unit; });

  // ---- Curriculum (Chapters / Topics / Upload) --------------------------

  Future<Either<Failure, List<AdminRecord>>> subjects(String classId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.subjectsByClass(classId));
        return res.dataList().whereType<Map>().map(AdminRecord.named).toList();
      });

  Future<Either<Failure, List<AdminRecord>>> chapters(
          String classId, String subjectId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.chapters(classId, subjectId));
        return res.dataList().whereType<Map>().map(AdminRecord.chapter).toList();
      });

  Future<Either<Failure, Unit>> createChapter(
          String classId, String subjectId, String name, int order) =>
      guardEither(() async {
        await _dio.post(Endpoints.chaptersRoot, data: {
          'classId': classId,
          'subjectId': subjectId,
          'name': name,
          'order': order,
        });
        return unit;
      });

  Future<Either<Failure, Unit>> deleteChapters(
          String classId, String subjectId, List<String> chapterIds) =>
      guardEither(() async {
        await _dio.delete(Endpoints.chaptersRoot, data: {
          'classId': classId,
          'subjectId': subjectId,
          'chapterIds': chapterIds,
        });
        return unit;
      });

  Future<Either<Failure, List<AdminRecord>>> topics(
          String classId, String subjectId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.topics(classId, subjectId));
        return res.dataList().whereType<Map>().map(AdminRecord.named).toList();
      });

  // ---- Relations / Mappings ---------------------------------------------

  Future<Either<Failure, List<AdminRecord>>> teacherStudentLinks(String schoolId) =>
      guardEither(() async {
        final res = await _dio
            .get(Endpoints.teacherStudents, queryParameters: {'schoolId': schoolId});
        return res.dataList().whereType<Map>().map(AdminRecord.link).toList();
      });

  Future<Either<Failure, Unit>> createTeacherStudentLink(
          {required String schoolId,
          required String teacherId,
          required List<String> studentIds,
          String? sectionId}) =>
      guardEither(() async {
        await _dio.post('${Endpoints.teacherStudents}/bulk', data: {
          'schoolId': schoolId,
          'teacherId': teacherId,
          'studentIds': studentIds,
          if (sectionId != null) 'sectionId': sectionId,
        });
        return unit;
      });
}

enum ALoad { initial, loading, loaded, error }

class AdminState extends Equatable {
  const AdminState({
    this.status = ALoad.initial,
    this.schools = const [],
    this.classes = const [],
    this.teachers = const [],
    this.students = const [],
    this.sections = const [],
    this.selectedSchoolId,
    this.error,
  });
  final ALoad status;
  final List<AdminRecord> schools;
  final List<AdminRecord> classes;
  final List<AdminRecord> teachers;
  final List<AdminRecord> students;
  final List<AdminRecord> sections;
  final String? selectedSchoolId;
  final String? error;

  AdminState copyWith({
    ALoad? status,
    List<AdminRecord>? schools,
    List<AdminRecord>? classes,
    List<AdminRecord>? teachers,
    List<AdminRecord>? students,
    List<AdminRecord>? sections,
    String? selectedSchoolId,
    String? error,
  }) =>
      AdminState(
        status: status ?? this.status,
        schools: schools ?? this.schools,
        classes: classes ?? this.classes,
        teachers: teachers ?? this.teachers,
        students: students ?? this.students,
        sections: sections ?? this.sections,
        selectedSchoolId: selectedSchoolId ?? this.selectedSchoolId,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, schools, classes, teachers, students, sections, selectedSchoolId, error];
}

class AdminCubit extends Cubit<AdminState> {
  AdminCubit(this._repo) : super(const AdminState());
  final AdminRepository _repo;

  Future<void> init() async {
    emit(state.copyWith(status: ALoad.loading));
    final schoolsR = await _repo.schools();
    final classesR = await _repo.classes();
    final schools = schoolsR.getOrElse(() => const []);
    emit(state.copyWith(
      status: ALoad.loaded,
      schools: schools,
      classes: classesR.getOrElse(() => const []),
    ));
    if (schools.isNotEmpty) selectSchool(schools.first.id);
  }

  Future<void> selectSchool(String schoolId) async {
    emit(state.copyWith(selectedSchoolId: schoolId));
    final t = await _repo.teachers(schoolId);
    final s = await _repo.students(schoolId);
    final sec = await _repo.sections(schoolId);
    emit(state.copyWith(
      teachers: t.getOrElse(() => const []),
      students: s.getOrElse(() => const []),
      sections: sec.getOrElse(() => const []),
    ));
  }

  Future<bool> createSection(String name) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null) return false;
    final r = await _repo.createSection(name, schoolId);
    if (r.isRight()) { await selectSchool(schoolId); return true; }
    return false;
  }

  Future<void> deleteTeacher(String id) async {
    await _repo.deleteTeacher(id);
    final schoolId = state.selectedSchoolId;
    if (schoolId != null) await selectSchool(schoolId);
  }

  Future<void> deleteSection(String id) async {
    await _repo.deleteSection(id);
    final schoolId = state.selectedSchoolId;
    if (schoolId != null) await selectSchool(schoolId);
  }

  Future<bool> createSchool(String name, String address) async {
    final r = await _repo.createSchool(name, address);
    if (r.isRight()) {
      final list = await _repo.schools();
      emit(state.copyWith(schools: list.getOrElse(() => state.schools)));
      return true;
    }
    return false;
  }

  Future<bool> createTeacher(String first, String last, String email) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null) return false;
    final r = await _repo.createTeacher(first, last, email, schoolId);
    if (r.isRight()) {
      await selectSchool(schoolId);
      return true;
    }
    return false;
  }

  Future<bool> createStudent(String first, String last, String email) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null) return false;
    final r = await _repo.createStudent(first, last, email, schoolId);
    if (r.isRight()) {
      await selectSchool(schoolId);
      return true;
    }
    return false;
  }
}
