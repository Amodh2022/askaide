import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/api_helpers.dart';
import '../../../core/network/endpoints.dart';

// ---- Models ----------------------------------------------------------------

class TeacherAssignment extends Equatable {
  const TeacherAssignment({
    required this.subjectId,
    required this.subjectName,
    required this.className,
    required this.studentCount,
  });
  final String subjectId;
  final String subjectName;
  final String className;
  final int studentCount;

  factory TeacherAssignment.fromJson(Map<dynamic, dynamic> j) {
    // The backend nests classes under `classes:[{className,...}]`; derive a
    // readable label from the first/joined class names when present.
    final classes = j.listAt(['classes']).whereType<Map>().toList();
    final classNames = classes
        .map((c) => c.str(['className', 'name']))
        .where((s) => s.isNotEmpty)
        .toList();
    return TeacherAssignment(
      subjectId: j.str(['subjectId', '_id', 'id']),
      subjectName: j.str(['subjectName', 'name'], 'Subject'),
      className: classNames.isNotEmpty
          ? classNames.join(', ')
          : j.str(['className', 'class'], ''),
      studentCount: j.intval(['totalStudents', 'studentCount', 'students']),
    );
  }

  @override
  List<Object?> get props => [subjectId, subjectName, className, studentCount];
}

class SubjectDashboard extends Equatable {
  const SubjectDashboard({
    this.subjectName = '',
    this.studentCount = 0,
    this.avgMastery = 0,
    this.avgCoverage = 0,
  });
  final String subjectName;
  final int studentCount;
  final double avgMastery; // 0..1
  final double avgCoverage; // 0..1

  factory SubjectDashboard.fromJson(Map<dynamic, dynamic> j) {
    // Real shape: { subject:{name}, overview:{totalStudents, avgSubjectMastery,
    // avgSubjectCoverage, ...} }. Fall back to a flat shape for tolerance.
    final subject = j['subject'] is Map ? j['subject'] as Map : const {};
    final o = j['overview'] is Map ? j['overview'] as Map : j;
    return SubjectDashboard(
      subjectName: subject.str(['name']).isNotEmpty
          ? subject.str(['name'])
          : j.str(['subjectName', 'name']),
      studentCount: o.intval(['totalStudents', 'studentCount']),
      avgMastery: _frac(o.dbl(['avgSubjectMastery', 'avgMastery', 'mastery'])),
      avgCoverage: _frac(o.dbl(['avgSubjectCoverage', 'avgCoverage', 'coverage'])),
    );
  }

  @override
  List<Object?> get props => [subjectName, studentCount, avgMastery, avgCoverage];
}

class StudentRow extends Equatable {
  const StudentRow({
    required this.id,
    required this.name,
    required this.mastery,
    required this.questionsAttempted,
    required this.status,
  });
  final String id;
  final String name;
  final double mastery;
  final int questionsAttempted;
  final String status;

  factory StudentRow.fromJson(Map<dynamic, dynamic> j) => StudentRow(
        id: j.str(['studentId', '_id', 'id']),
        name: j.str(['name', 'studentName'], 'Student'),
        mastery: _frac(j.dbl(['subjectMastery', 'mastery'])),
        questionsAttempted:
            j.intval(['chaptersCompleted', 'questionsAttempted']),
        status: j.str(['status'], ''),
      );

  @override
  List<Object?> get props => [id, name, mastery, questionsAttempted, status];
}

class WeakTopicRow extends Equatable {
  const WeakTopicRow({required this.name, required this.mastery, required this.studentCount});
  final String name;
  final double mastery;
  final int studentCount;

  factory WeakTopicRow.fromJson(Map<dynamic, dynamic> j) => WeakTopicRow(
        name: j.str(['topicName', 'name'], 'Topic'),
        mastery: _frac(j.dbl(['avgMastery', 'mastery'])),
        studentCount: j.intval(['studentsWeak', 'studentCount']),
      );

  @override
  List<Object?> get props => [name, mastery, studentCount];
}

class ActivityItem extends Equatable {
  const ActivityItem({required this.studentName, required this.action, required this.timestamp});
  final String studentName;
  final String action;
  final String timestamp;

  factory ActivityItem.fromJson(Map<dynamic, dynamic> j) {
    // Real shape: { type, student:{name}, timestamp, ... }.
    final student = j['student'] is Map ? j['student'] as Map : const {};
    final studentName = student.str(['name']);
    return ActivityItem(
      studentName:
          studentName.isNotEmpty ? studentName : j.str(['studentName', 'name'], 'Student'),
      action: j.str(['type', 'action', 'description'], 'practised'),
      timestamp: j.str(['timestamp', 'createdAt']),
    );
  }

  @override
  List<Object?> get props => [studentName, action, timestamp];
}

class StudentProgressData extends Equatable {
  const StudentProgressData({this.studentName = '', this.overallMastery = 0, this.chapters = const []});
  final String studentName;
  final double overallMastery;
  final List<WeakTopicRow> chapters;

  factory StudentProgressData.fromJson(Map<dynamic, dynamic> j) {
    // Real shape: { student:{name}, subjectSummary:{overallMastery,...},
    // chapters:[{name, mastery, coverage, ...}] }.
    final student = j['student'] is Map ? j['student'] as Map : const {};
    final summary =
        j['subjectSummary'] is Map ? j['subjectSummary'] as Map : j;
    final studentName = student.str(['name']);
    return StudentProgressData(
      studentName:
          studentName.isNotEmpty ? studentName : j.str(['studentName', 'name']),
      overallMastery: _frac(summary.dbl(['overallMastery', 'mastery'])),
      chapters: j
          .listAt(['chapters', 'chapterProgress'])
          .whereType<Map>()
          .map((m) => WeakTopicRow(
                name: m.str(['name', 'chapterName'], 'Chapter'),
                mastery: _frac(m.dbl(['mastery'])),
                studentCount: m.intval(['coverage', 'questionsAttempted']),
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [studentName, overallMastery, chapters];
}

/// Chapter-level analytics for a subject (mirrors React `getChapterAnalytics`).
class ChapterAnalytics extends Equatable {
  const ChapterAnalytics({
    this.chapterName = '',
    this.avgMastery = 0,
    this.avgCoverage = 0,
    this.studentsAttempted = 0,
    this.topics = const [],
  });
  final String chapterName;
  final double avgMastery; // 0..1
  final double avgCoverage; // 0..1
  final int studentsAttempted;
  final List<WeakTopicRow> topics;

  factory ChapterAnalytics.fromJson(Map<dynamic, dynamic> j) {
    // Real shape: { chapter:{name}, overview:{classAvgMastery, classAvgCoverage,
    // totalTopics}, topics:[{name, classAvgMastery, studentsAttempted, ...}] }.
    final chapter = j['chapter'] is Map ? j['chapter'] as Map : const {};
    final o = j['overview'] is Map ? j['overview'] as Map : j;
    return ChapterAnalytics(
      chapterName: chapter.str(['name']).isNotEmpty
          ? chapter.str(['name'])
          : j.str(['chapterName', 'name']),
      avgMastery: _frac(o.dbl(['classAvgMastery', 'avgMastery', 'mastery'])),
      avgCoverage: _frac(o.dbl(['classAvgCoverage', 'avgCoverage', 'coverage'])),
      studentsAttempted: o.intval(['studentsAttempted', 'studentCount']),
      topics: j
          .listAt(['topics', 'topicBreakdown'])
          .whereType<Map>()
          .map((m) => WeakTopicRow(
                name: m.str(['name', 'topicName'], 'Topic'),
                mastery: _frac(m.dbl(['classAvgMastery', 'avgMastery', 'mastery'])),
                studentCount: m.intval(['studentsAttempted', 'studentsWeak', 'studentCount']),
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [chapterName, avgMastery, avgCoverage, studentsAttempted, topics];
}

double _frac(double v) => v > 1 ? v / 100 : v;

// ---- Repository ------------------------------------------------------------

class TeacherRepository {
  TeacherRepository(this._dio);
  final Dio _dio;

  Future<Either<Failure, List<TeacherAssignment>>> assignments(String teacherId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.teacherAssignments(teacherId));
        return res
            .dataList(['assignments'])
            .whereType<Map>()
            .map(TeacherAssignment.fromJson)
            .toList();
      });

  Future<Either<Failure, SubjectDashboard>> subjectDashboard(
          String teacherId, String subjectId) =>
      guardEither(() async {
        final res =
            await _dio.get(Endpoints.teacherSubjectDashboard(teacherId, subjectId));
        return SubjectDashboard.fromJson(res.dataMap());
      });

  Future<Either<Failure, List<StudentRow>>> students(
          String teacherId, String subjectId,
          {String? classId,
          String? sectionId,
          String? status,
          String? sortBy,
          String? order}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.teacherStudentsList(teacherId, subjectId),
          queryParameters: {
            if (classId != null) 'classId': classId,
            if (sectionId != null) 'sectionId': sectionId,
            if (status != null) 'status': status,
            if (sortBy != null) 'sortBy': sortBy,
            if (order != null) 'order': order,
          },
        );
        return res.dataList(['students']).whereType<Map>().map(StudentRow.fromJson).toList();
      });

  Future<Either<Failure, List<WeakTopicRow>>> weakTopics(
          String teacherId, String subjectId,
          {String? classId, String? sectionId, double? threshold}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.teacherWeakTopics(teacherId, subjectId),
          queryParameters: {
            if (classId != null) 'classId': classId,
            if (sectionId != null) 'sectionId': sectionId,
            if (threshold != null) 'threshold': threshold,
          },
        );
        return res.dataList(['weakTopics']).whereType<Map>().map(WeakTopicRow.fromJson).toList();
      });

  Future<Either<Failure, List<ActivityItem>>> activity(
          String teacherId, String subjectId, {int limit = 20}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.teacherActivity(teacherId, subjectId),
          queryParameters: {'limit': limit},
        );
        return res.dataList(['activities']).whereType<Map>().map(ActivityItem.fromJson).toList();
      });

  Future<Either<Failure, ChapterAnalytics>> chapterAnalytics(
          String teacherId, String subjectId, String chapterId,
          {String? classId, String? sectionId}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.teacherChapterAnalytics(teacherId, subjectId, chapterId),
          queryParameters: {
            if (classId != null) 'classId': classId,
            if (sectionId != null) 'sectionId': sectionId,
          },
        );
        return ChapterAnalytics.fromJson(res.dataMap());
      });

  Future<Either<Failure, StudentProgressData>> studentProgress(
          String teacherId, String studentId, String subjectId) =>
      guardEither(() async {
        final res = await _dio
            .get(Endpoints.teacherStudentProgress(teacherId, studentId, subjectId));
        return StudentProgressData.fromJson(res.dataMap());
      });
}

// ---- Cubits ----------------------------------------------------------------

enum TLoad { initial, loading, loaded, error }

class TeacherHomeState extends Equatable {
  const TeacherHomeState({this.status = TLoad.initial, this.assignments = const [], this.error});
  final TLoad status;
  final List<TeacherAssignment> assignments;
  final String? error;

  TeacherHomeState copyWith({TLoad? status, List<TeacherAssignment>? assignments, String? error}) =>
      TeacherHomeState(
          status: status ?? this.status,
          assignments: assignments ?? this.assignments,
          error: error);

  @override
  List<Object?> get props => [status, assignments, error];
}

class TeacherHomeCubit extends Cubit<TeacherHomeState> {
  TeacherHomeCubit(this._repo) : super(const TeacherHomeState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId) async {
    if (teacherId.isEmpty) return;
    emit(state.copyWith(status: TLoad.loading));
    final r = await _repo.assignments(teacherId);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error, error: f.message)),
      (list) => emit(state.copyWith(status: TLoad.loaded, assignments: list)),
    );
  }
}

class TeacherSubjectState extends Equatable {
  const TeacherSubjectState({
    this.status = TLoad.initial,
    this.dashboard = const SubjectDashboard(),
    this.students = const [],
    this.weakTopics = const [],
    this.activity = const [],
    this.error,
  });
  final TLoad status;
  final SubjectDashboard dashboard;
  final List<StudentRow> students;
  final List<WeakTopicRow> weakTopics;
  final List<ActivityItem> activity;
  final String? error;

  TeacherSubjectState copyWith({
    TLoad? status,
    SubjectDashboard? dashboard,
    List<StudentRow>? students,
    List<WeakTopicRow>? weakTopics,
    List<ActivityItem>? activity,
    String? error,
  }) =>
      TeacherSubjectState(
        status: status ?? this.status,
        dashboard: dashboard ?? this.dashboard,
        students: students ?? this.students,
        weakTopics: weakTopics ?? this.weakTopics,
        activity: activity ?? this.activity,
        error: error,
      );

  @override
  List<Object?> get props => [status, dashboard, students, weakTopics, activity, error];
}

class TeacherSubjectCubit extends Cubit<TeacherSubjectState> {
  TeacherSubjectCubit(this._repo) : super(const TeacherSubjectState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, String subjectId) async {
    emit(state.copyWith(status: TLoad.loading));
    final results = await Future.wait([
      _repo.subjectDashboard(teacherId, subjectId),
      _repo.students(teacherId, subjectId),
      _repo.weakTopics(teacherId, subjectId),
      _repo.activity(teacherId, subjectId),
    ]);
    emit(state.copyWith(
      status: TLoad.loaded,
      dashboard: (results[0] as Either<Failure, SubjectDashboard>)
          .getOrElse(() => const SubjectDashboard()),
      students: (results[1] as Either<Failure, List<StudentRow>>).getOrElse(() => const []),
      weakTopics: (results[2] as Either<Failure, List<WeakTopicRow>>).getOrElse(() => const []),
      activity: (results[3] as Either<Failure, List<ActivityItem>>).getOrElse(() => const []),
    ));
  }
}

class TeacherStudentState extends Equatable {
  const TeacherStudentState({this.status = TLoad.initial, this.data = const StudentProgressData()});
  final TLoad status;
  final StudentProgressData data;

  TeacherStudentState copyWith({TLoad? status, StudentProgressData? data}) =>
      TeacherStudentState(status: status ?? this.status, data: data ?? this.data);

  @override
  List<Object?> get props => [status, data];
}

class TeacherStudentCubit extends Cubit<TeacherStudentState> {
  TeacherStudentCubit(this._repo) : super(const TeacherStudentState());
  final TeacherRepository _repo;

  Future<void> load(String teacherId, String studentId, String subjectId) async {
    emit(state.copyWith(status: TLoad.loading));
    final r = await _repo.studentProgress(teacherId, studentId, subjectId);
    r.fold(
      (f) => emit(state.copyWith(status: TLoad.error)),
      (d) => emit(state.copyWith(status: TLoad.loaded, data: d)),
    );
  }
}
