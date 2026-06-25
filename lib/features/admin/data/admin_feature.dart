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
        // Card shows "Code: {schoolCode}" (mirrors React SchoolManagement).
        subtitle: j.str(['schoolCode']),
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
    final topics = j['topics'];
    final topicCount = topics is List ? topics.length : j.intval(['topicCount']);
    final parts = <String>[
      if (order > 0) 'Chapter $order',
      if (topicCount > 0) '$topicCount topics',
    ];
    return AdminRecord(
      id: j.str(['_id', 'id']),
      name: j.str(['name', 'chapterName'], 'Chapter'),
      subtitle: parts.join(' · '),
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

/// A section with strength + active state (mirrors React SectionManagement card).
class AdminSection extends Equatable {
  const AdminSection({
    required this.id,
    required this.name,
    this.maxStrength = 40,
    this.currentStrength = 0,
    this.isActive = true,
  });
  final String id;
  final String name;
  final int maxStrength;
  final int currentStrength;
  final bool isActive;

  factory AdminSection.fromJson(Map<dynamic, dynamic> j) => AdminSection(
        id: j.str(['_id', 'id']),
        name: j.str(['displayName', 'name'], 'Section'),
        maxStrength: j.intval(['maxStrength'], 40),
        currentStrength: j.intval(['currentStrength']),
        isActive: j.boolean(['isActive'], true),
      );

  @override
  List<Object?> get props => [id, name, maxStrength, currentStrength, isActive];
}

/// A populated teacher↔student link (mirrors React RelationView row). Refs come
/// back as nested objects under snake_case keys; tolerate camelCase too.
class AdminLink extends Equatable {
  const AdminLink({
    required this.id,
    required this.teacherName,
    required this.teacherEmail,
    required this.studentName,
    required this.studentEmail,
    required this.className,
    required this.sectionName,
    required this.subjectName,
  });
  final String id;
  final String teacherName;
  final String teacherEmail;
  final String studentName;
  final String studentEmail;
  final String className;
  final String sectionName;
  final String subjectName;

  factory AdminLink.fromJson(Map<dynamic, dynamic> j) {
    Map<dynamic, dynamic> asMap(dynamic v) => v is Map ? v : const {};
    final t = asMap(j['teacher_id'] ?? j['teacher']);
    final s = asMap(j['student_id'] ?? j['student']);
    final cl = asMap(j['class_id'] ?? j['class']);
    final sec = asMap(j['section_id'] ?? j['section']);
    final sub = asMap(j['_subject_id'] ?? j['subject']);
    String nameOf(Map<dynamic, dynamic> m, String fb) {
      final n = [m.str(['firstName']), m.str(['lastName'])].where((x) => x.isNotEmpty).join(' ');
      return n.isEmpty ? m.str(['name'], fb) : n;
    }
    return AdminLink(
      id: j.str(['_id', 'id']),
      teacherName: t.isEmpty ? j.str(['teacherName'], 'Teacher') : nameOf(t, 'Teacher'),
      teacherEmail: t.str(['email']),
      studentName: s.isEmpty ? j.str(['studentName'], 'Student') : nameOf(s, 'Student'),
      studentEmail: s.str(['email']),
      className: cl.str(['name', 'displayName']),
      sectionName: sec.str(['displayName', 'name']),
      subjectName: sub.str(['name']),
    );
  }

  @override
  List<Object?> get props =>
      [id, teacherName, teacherEmail, studentName, studentEmail, className, sectionName, subjectName];
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

  /// Creates a school. React's create form sends schoolName/schoolCode/
  /// schoolAddress/schoolBoard (required) plus optional phone/email/website,
  /// so we pass the assembled map through verbatim.
  Future<Either<Failure, Unit>> createSchool(Map<String, dynamic> data) =>
      guardEither(() async {
        await _dio.post(Endpoints.school, data: data);
        return unit;
      });

  /// Creates a teacher. `POST /teacher` expects a single teacher **object**
  /// (the API rejects an array body with "value must be of type object").
  Future<Either<Failure, Unit>> createTeacher(
          String name, String email, String password, String phone, String schoolId) =>
      guardEither(() async {
        await _dio.post(Endpoints.teacher, data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone.isNotEmpty) 'phone': phone,
          'schoolId': schoolId,
        });
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

  /// Bulk-creates sections from a list of names within a class (React's
  /// comma-separated "Bulk Add" form → `{schoolId, classId, sections: [names]}`).
  Future<Either<Failure, Unit>> createSectionsBulk(
          String schoolId, String classId, List<String> names) =>
      guardEither(() async {
        await _dio.post(Endpoints.sectionsBulk,
            data: {'schoolId': schoolId, 'classId': classId, 'sections': names});
        return unit;
      });

  /// Sections scoped to a school+class with strength/active detail (React lists
  /// sections only after both school and class are chosen).
  Future<Either<Failure, List<AdminSection>>> sectionsDetailed(
          String schoolId, String classId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.sectionsByClass(schoolId, classId));
        return res.dataList().whereType<Map>().map(AdminSection.fromJson).toList();
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

  /// Populated teacher↔student links for the Relations table (with class/
  /// section/subject + emails). Mirrors React RelationView's data source.
  Future<Either<Failure, List<AdminLink>>> teacherStudentLinksDetailed(String schoolId) =>
      guardEither(() async {
        final res = await _dio
            .get(Endpoints.teacherStudents, queryParameters: {'schoolId': schoolId});
        return res.dataList().whereType<Map>().map(AdminLink.fromJson).toList();
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

  // ---- Bulk create (multi-row add, mirrors React useFieldArray) ----------

  /// Creates several teachers. `POST /teacher` accepts a single object only, so
  /// each row `{name,email,password,phone?}` (stamped with [schoolId]) is posted
  /// individually.
  Future<Either<Failure, Unit>> createTeachers(
          List<Map<String, dynamic>> people, String schoolId) =>
      guardEither(() async {
        for (final p in people) {
          await _dio.post(Endpoints.teacher, data: {...p, 'schoolId': schoolId});
        }
        return unit;
      });

  /// Creates several students at once via `POST /student/create`.
  Future<Either<Failure, Unit>> createStudents(
          List<Map<String, dynamic>> people, String schoolId) =>
      guardEither(() async {
        await _dio.post(Endpoints.studentCreate, data: [
          for (final p in people) {...p, 'schoolId': schoolId},
        ]);
        return unit;
      });

  // ---- Overview metrics (SuperAdmin) -------------------------------------
  // Each returns the inner `data` object; query params drop empties so we
  // never send blank filters (mirrors React `cleanParams`).

  Future<Either<Failure, Map<String, dynamic>>> overviewMetrics() =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.adminMetricsOverview);
        return res.dataMap();
      });

  Future<Either<Failure, Map<String, dynamic>>> userMetrics(
          {String? from, String? to}) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.adminMetricsUsers,
            queryParameters: _clean({'from': from, 'to': to}));
        return res.dataMap();
      });

  Future<Either<Failure, Map<String, dynamic>>> contentMetrics(
          {String? classId, String? subjectId}) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.adminMetricsContent,
            queryParameters: _clean({'classId': classId, 'subjectId': subjectId}));
        return res.dataMap();
      });

  Future<Either<Failure, Map<String, dynamic>>> questionJobMetrics() =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.adminMetricsQuestionJobs);
        return res.dataMap();
      });

  Future<Either<Failure, Map<String, dynamic>>> engagementMetrics(
          {String? from, String? to, String? classId, String? subjectId}) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.adminMetricsEngagement,
            queryParameters: _clean(
                {'from': from, 'to': to, 'classId': classId, 'subjectId': subjectId}));
        return res.dataMap();
      });

  /// Drops null/empty values so blank filters aren't sent as query params.
  static Map<String, dynamic> _clean(Map<String, dynamic> params) => {
        for (final e in params.entries)
          if (e.value != null && e.value != '') e.key: e.value,
      };
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

  Future<bool> createSchool(Map<String, dynamic> data) async {
    final r = await _repo.createSchool(data);
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

  /// Bulk-creates teachers from multi-row form data (mirrors React multi-add).
  Future<bool> createTeachers(List<Map<String, dynamic>> people) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null || people.isEmpty) return false;
    final r = await _repo.createTeachers(people, schoolId);
    if (r.isRight()) { await selectSchool(schoolId); return true; }
    return false;
  }

  /// Bulk-creates students from multi-row form data.
  Future<bool> createStudents(List<Map<String, dynamic>> people) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null || people.isEmpty) return false;
    final r = await _repo.createStudents(people, schoolId);
    if (r.isRight()) { await selectSchool(schoolId); return true; }
    return false;
  }

  /// Creates a section scoped to a class (React always sends `classId`).
  Future<bool> createSectionFull(
      {required String name, String? classId, int? maxStrength}) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null) return false;
    final r = await _repo.createSection(name, schoolId,
        classId: classId, maxStrength: maxStrength);
    if (r.isRight()) { await selectSchool(schoolId); return true; }
    return false;
  }

  Future<bool> updateSchool(String id, Map<String, dynamic> data) async {
    final r = await _repo.updateSchool(id, data);
    if (r.isRight()) {
      final list = await _repo.schools();
      emit(state.copyWith(schools: list.getOrElse(() => state.schools)));
      return true;
    }
    return false;
  }

  Future<bool> updateTeacher(String id, Map<String, dynamic> data) async {
    final r = await _repo.updateTeacher(id, data);
    final schoolId = state.selectedSchoolId;
    if (r.isRight() && schoolId != null) { await selectSchool(schoolId); return true; }
    return r.isRight();
  }

  Future<bool> updateSection(String id, Map<String, dynamic> data) async {
    final r = await _repo.updateSection(id, data);
    final schoolId = state.selectedSchoolId;
    if (r.isRight() && schoolId != null) { await selectSchool(schoolId); return true; }
    return r.isRight();
  }
}
