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
        name: j.str(['schoolName', 'name'], 'School'),
        // Schools expose `schoolCode` as the secondary label (no address field).
        subtitle: j.str(['schoolCode', 'address', 'city']),
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
        // Sections expose `displayName`; classes/topics use `name`.
        name: j.str(['displayName', 'name', 'topicName', 'chapterName'], 'Item'),
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
    // Populated link refs come back snake_case (`teacher_id`/`student_id`) with
    // a single `name`; tolerate the camelCase/first+last shape too.
    final teacher = j['teacher_id'] is Map
        ? j['teacher_id'] as Map
        : (j['teacher'] is Map ? j['teacher'] as Map : const {});
    final student = j['student_id'] is Map
        ? j['student_id'] as Map
        : (j['student'] is Map ? j['student'] as Map : const {});
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

  Future<Either<Failure, Unit>> createSchool(
          String name, String code, String address) =>
      guardEither(() async {
        await _dio.post(Endpoints.school, data: {
          'schoolName': name,
          if (code.isNotEmpty) 'schoolCode': code,
          if (address.isNotEmpty) 'schoolAddress': address,
        });
        return unit;
      });

  /// Creates a teacher. The backend accepts a bulk **array** of teacher
  /// objects on `POST /teacher` (mirrors React `createTeacher`).
  Future<Either<Failure, Unit>> createTeacher(
          String name, String email, String password, String phone, String schoolId) =>
      guardEither(() async {
        await _dio.post(Endpoints.teacher, data: [
          {
            'name': name,
            'email': email,
            'password': password,
            if (phone.isNotEmpty) 'phone': phone,
            'schoolId': schoolId,
          }
        ]);
        return unit;
      });

  /// Creates a student. `POST /student/create` accepts a bulk **array** of
  /// student objects (mirrors React `createStudent`).
  Future<Either<Failure, Unit>> createStudent(
          String name, String email, String password, String phone, String schoolId) =>
      guardEither(() async {
        await _dio.post(Endpoints.studentCreate, data: [
          {
            'name': name,
            'email': email,
            'password': password,
            if (phone.isNotEmpty) 'phone': phone,
            'schoolId': schoolId,
          }
        ]);
        return unit;
      });

  Future<Either<Failure, List<AdminRecord>>> sections(String schoolId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.sectionsBySchool(schoolId));
        return res.dataList().whereType<Map>().map(AdminRecord.named).toList();
      });

  Future<Either<Failure, Unit>> createSection(String name, String schoolId,
          {String? classId, int? maxStrength}) =>
      guardEither(() async {
        await _dio.post(Endpoints.sections, data: {
          'schoolId': schoolId,
          if (classId != null) 'classId': classId,
          'name': name,
          if (maxStrength != null) 'maxStrength': maxStrength,
        });
        return unit;
      });

  Future<Either<Failure, Unit>> bulkCreateSections(Map<String, dynamic> data) =>
      guardEither(() async {
        await _dio.post(Endpoints.sectionsBulk, data: data);
        return unit;
      });

  Future<Either<Failure, List<AdminRecord>>> sectionsByClass(
          String schoolId, String classId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.sectionsByClass(schoolId, classId));
        return res.dataList().whereType<Map>().map(AdminRecord.named).toList();
      });

  Future<Either<Failure, AdminRecord>> sectionById(String sectionId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.sectionById(sectionId));
        return AdminRecord.named(res.dataMap());
      });

  Future<Either<Failure, Unit>> updateSection(
          String sectionId, Map<String, dynamic> data) =>
      guardEither(() async {
        await _dio.put(Endpoints.sectionById(sectionId), data: data);
        return unit;
      });

  Future<Either<Failure, Unit>> deleteSection(String id) =>
      guardEither(() async { await _dio.delete(Endpoints.sectionById(id)); return unit; });

  Future<Either<Failure, Unit>> updateSchool(String id, Map<String, dynamic> data) =>
      guardEither(() async { await _dio.put(Endpoints.schoolById(id), data: data); return unit; });

  Future<Either<Failure, Unit>> updateTeacher(String id, Map<String, dynamic> data) =>
      guardEither(() async { await _dio.put(Endpoints.teacherById(id), data: data); return unit; });

  Future<Either<Failure, Unit>> deleteTeacher(String id) =>
      guardEither(() async { await _dio.delete(Endpoints.teacherById(id)); return unit; });

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

  /// Bulk-links a teacher to students. The backend expects snake_case link
  /// objects under `data`, one per student (mirrors React `LinkManagement`):
  /// `{ data: [{ school_id, teacher_id, student_id, class_id?, section_id?,
  /// _subject_id? }] }`.
  Future<Either<Failure, Unit>> createTeacherStudentLink(
          {required String schoolId,
          required String teacherId,
          required List<String> studentIds,
          String? sectionId,
          String? classId,
          String? subjectId}) =>
      guardEither(() async {
        await _dio.post(Endpoints.teacherStudentsBulk, data: {
          'data': [
            for (final studentId in studentIds)
              {
                'school_id': schoolId,
                'teacher_id': teacherId,
                'student_id': studentId,
                if (classId != null) 'class_id': classId,
                if (sectionId != null) 'section_id': sectionId,
                if (subjectId != null) '_subject_id': subjectId,
              }
          ],
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

  Future<bool> createSection(String name, {String? classId, int? maxStrength}) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null) return false;
    final r = await _repo.createSection(name, schoolId,
        classId: classId, maxStrength: maxStrength);
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

  Future<bool> createSchool(String name, String code, String address) async {
    final r = await _repo.createSchool(name, code, address);
    if (r.isRight()) {
      final list = await _repo.schools();
      emit(state.copyWith(schools: list.getOrElse(() => state.schools)));
      return true;
    }
    return false;
  }

  Future<bool> createTeacher(
      String name, String email, String password, String phone) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null) return false;
    final r = await _repo.createTeacher(name, email, password, phone, schoolId);
    if (r.isRight()) {
      await selectSchool(schoolId);
      return true;
    }
    return false;
  }

  Future<bool> createStudent(
      String name, String email, String password, String phone) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null) return false;
    final r = await _repo.createStudent(name, email, password, phone, schoolId);
    if (r.isRight()) {
      await selectSchool(schoolId);
      return true;
    }
    return false;
  }
}
