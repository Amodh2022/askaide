import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/failures.dart';
import '../../core/network/api_helpers.dart';
import '../../core/network/endpoints.dart';

class Child extends Equatable {
  const Child({required this.id, required this.name, required this.grade});
  final String id;
  final String name;
  final String grade;

  factory Child.fromJson(Map<dynamic, dynamic> j) => Child(
        id: j.str(['childId', '_id', 'id']),
        name: j.str(['name', 'childName'], 'Child'),
        grade: j.str(['className', 'grade']),
      );

  @override
  List<Object?> get props => [id, name, grade];
}

class ChildOverview extends Equatable {
  const ChildOverview({
    this.childName = '',
    this.streakDays = 0,
    this.overallMastery = 0,
  });
  final String childName;
  final int streakDays;
  final double overallMastery;

  factory ChildOverview.fromJson(Map<dynamic, dynamic> j) => ChildOverview(
        childName: j.str(['childName', 'name']),
        streakDays: j.intval(['currentStreak', 'streakDays']),
        // The overview headline figure is `overallAccuracy` (0..100); keep the
        // older `mastery`/`overallMastery` aliases for tolerance.
        overallMastery: () {
          final v = j.dbl(['overallAccuracy', 'overallMastery', 'mastery']);
          return v > 1 ? v / 100 : v;
        }(),
      );

  @override
  List<Object?> get props => [childName, streakDays, overallMastery];
}

double _frac(double v) => v > 1 ? v / 100 : v;

/// A chapter/topic mastery row used inside a child's subject progress.
class ChapterMastery extends Equatable {
  const ChapterMastery({required this.name, required this.mastery, this.coverage = 0});
  final String name;
  final double mastery; // 0..1
  final double coverage; // 0..1

  factory ChapterMastery.fromJson(Map<dynamic, dynamic> j) => ChapterMastery(
        name: j.str(['chapterName', 'topicName', 'name'], 'Chapter'),
        mastery: _frac(j.dbl(['mastery'])),
        coverage: _frac(j.dbl(['coverage'])),
      );

  @override
  List<Object?> get props => [name, mastery, coverage];
}

/// A child's progress within a single subject (mirrors React
/// `getChildSubjectProgress`).
class ChildSubjectProgress extends Equatable {
  const ChildSubjectProgress({
    this.subjectName = '',
    this.overallMastery = 0,
    this.coverage = 0,
    this.chapters = const [],
  });
  final String subjectName;
  final double overallMastery; // 0..1
  final double coverage; // 0..1
  final List<ChapterMastery> chapters;

  factory ChildSubjectProgress.fromJson(Map<dynamic, dynamic> j) => ChildSubjectProgress(
        subjectName: j.str(['subjectName', 'name']),
        overallMastery: _frac(j.dbl(['overallMastery', 'mastery'])),
        coverage: _frac(j.dbl(['coverage'])),
        chapters: j
            .listAt(['chapterProgress', 'chapters', 'topics'])
            .whereType<Map>()
            .map(ChapterMastery.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [subjectName, overallMastery, coverage, chapters];
}

/// A weak topic for a child within a subject (mirrors `getChildWeakTopics`).
class ChildWeakTopic extends Equatable {
  const ChildWeakTopic({required this.name, required this.mastery, this.chapterName = ''});
  final String name;
  final double mastery; // 0..1
  final String chapterName;

  factory ChildWeakTopic.fromJson(Map<dynamic, dynamic> j) => ChildWeakTopic(
        name: j.str(['topicName', 'name'], 'Topic'),
        mastery: _frac(j.dbl(['mastery'])),
        chapterName: j.str(['chapterName']),
      );

  @override
  List<Object?> get props => [name, mastery, chapterName];
}

/// A single entry in a child's activity feed (mirrors `getChildActivity`).
class ChildActivityItem extends Equatable {
  const ChildActivityItem({required this.action, required this.timestamp, this.detail = ''});
  final String action;
  final String timestamp;
  final String detail;

  factory ChildActivityItem.fromJson(Map<dynamic, dynamic> j) => ChildActivityItem(
        action: j.str(['action', 'type', 'description'], 'practised'),
        timestamp: j.str(['timestamp', 'createdAt']),
        detail: j.str(['detail', 'subjectName', 'chapterName']),
      );

  @override
  List<Object?> get props => [action, timestamp, detail];
}

/// A parent↔student link record (Admin/Principal management view).
class ParentStudentLink extends Equatable {
  const ParentStudentLink({required this.id, required this.parentName, required this.studentName});
  final String id;
  final String parentName;
  final String studentName;

  static String _nameOf(dynamic v, String fallback) {
    if (v is Map) {
      final full = [v.str(['firstName']), v.str(['lastName'])]
          .where((s) => s.isNotEmpty)
          .join(' ')
          .trim();
      return full.isEmpty ? v.str(['name', 'email'], fallback) : full;
    }
    return fallback;
  }

  factory ParentStudentLink.fromJson(Map<dynamic, dynamic> j) => ParentStudentLink(
        id: j.str(['_id', 'id']),
        parentName: _nameOf(j['parent'], j.str(['parentName'], 'Parent')),
        studentName: _nameOf(j['student'], j.str(['studentName'], 'Student')),
      );

  @override
  List<Object?> get props => [id, parentName, studentName];
}

abstract class ParentRepository {
  Future<Either<Failure, List<Child>>> children();
  Future<Either<Failure, ChildOverview>> overview(String childId);
  Future<Either<Failure, ChildSubjectProgress>> subjectProgress(
      String childId, String subjectId);
  Future<Either<Failure, List<ChildWeakTopic>>> weakTopics(
      String childId, String subjectId);
  Future<Either<Failure, List<ChildActivityItem>>> activity(String childId,
      {int limit = 20});
  Future<Either<Failure, List<ParentStudentLink>>> links({
    String? parentId,
    String? studentId,
  });
  Future<Either<Failure, Unit>> linkBulk(Map<String, dynamic> data);
  Future<Either<Failure, Unit>> unlinkChild(String studentId);
}

class ParentRepositoryImpl implements ParentRepository {
  ParentRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<Either<Failure, List<Child>>> children() => guardEither(() async {
        final res = await _dio.get(Endpoints.parentChildren);
        return res.dataList(['children']).whereType<Map>().map(Child.fromJson).toList();
      });

  @override
  Future<Either<Failure, ChildOverview>> overview(String childId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.parentChildOverview(childId));
        return ChildOverview.fromJson(res.dataMap());
      });

  @override
  Future<Either<Failure, ChildSubjectProgress>> subjectProgress(
          String childId, String subjectId) =>
      guardEither(() async {
        final res =
            await _dio.get(Endpoints.parentChildSubjectProgress(childId, subjectId));
        return ChildSubjectProgress.fromJson(res.dataMap());
      });

  @override
  Future<Either<Failure, List<ChildWeakTopic>>> weakTopics(
          String childId, String subjectId) =>
      guardEither(() async {
        final res =
            await _dio.get(Endpoints.parentChildWeakTopics(childId, subjectId));
        return res
            .dataList(['weakTopics', 'topics'])
            .whereType<Map>()
            .map(ChildWeakTopic.fromJson)
            .toList();
      });

  @override
  Future<Either<Failure, List<ChildActivityItem>>> activity(
          String childId, {int limit = 20}) =>
      guardEither(() async {
        final res = await _dio.get(
          Endpoints.parentChildActivity(childId),
          queryParameters: {'limit': limit},
        );
        return res
            .dataList(['activities', 'activity'])
            .whereType<Map>()
            .map(ChildActivityItem.fromJson)
            .toList();
      });

  // ---- Parent ↔ Student linking (Admin/Principal + parent self-service) ----

  @override
  Future<Either<Failure, List<ParentStudentLink>>> links({
    String? parentId,
    String? studentId,
  }) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.parentStudents, queryParameters: {
          if (parentId != null) 'parentId': parentId,
          if (studentId != null) 'studentId': studentId,
        });
        return res
            .dataList(['links'])
            .whereType<Map>()
            .map(ParentStudentLink.fromJson)
            .toList();
      });

  @override
  Future<Either<Failure, Unit>> linkBulk(Map<String, dynamic> data) =>
      guardEither(() async {
        await _dio.post(Endpoints.parentStudentsBulk, data: data);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> unlinkChild(String studentId) =>
      guardEither(() async {
        await _dio.delete(Endpoints.parentStudentUnlink(studentId));
        return unit;
      });
}

enum PLoad { initial, loading, loaded, error }

class ParentState extends Equatable {
  const ParentState({
    this.status = PLoad.initial,
    this.children = const [],
    this.overview,
    this.selectedChildId,
    this.childActivity = const [],
    this.error,
  });
  final PLoad status;
  final List<Child> children;
  final ChildOverview? overview;
  final String? selectedChildId;
  final List<ChildActivityItem> childActivity;
  final String? error;

  ParentState copyWith({
    PLoad? status,
    List<Child>? children,
    ChildOverview? overview,
    String? selectedChildId,
    List<ChildActivityItem>? childActivity,
    String? error,
  }) =>
      ParentState(
        status: status ?? this.status,
        children: children ?? this.children,
        overview: overview ?? this.overview,
        selectedChildId: selectedChildId ?? this.selectedChildId,
        childActivity: childActivity ?? this.childActivity,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, children, overview, selectedChildId, childActivity, error];
}

class ParentCubit extends Cubit<ParentState> {
  ParentCubit(this._repo) : super(const ParentState());
  final ParentRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: PLoad.loading));
    final r = await _repo.children();
    await r.fold(
      (f) async => emit(state.copyWith(status: PLoad.error, error: f.message)),
      (children) async {
        emit(state.copyWith(status: PLoad.loaded, children: children));
        if (children.isNotEmpty) await selectChild(children.first.id);
      },
    );
  }

  /// Loads the overview and recent activity feed for the chosen child.
  Future<void> selectChild(String childId) async {
    emit(state.copyWith(selectedChildId: childId, childActivity: const []));
    final ov = await _repo.overview(childId);
    ov.fold((_) {}, (o) => emit(state.copyWith(overview: o)));
    final act = await _repo.activity(childId);
    act.fold((_) {}, (a) => emit(state.copyWith(childActivity: a)));
  }

  /// Per-subject drill-down for the currently selected child.
  Future<ChildSubjectProgress?> subjectProgress(String subjectId) async {
    final childId = state.selectedChildId;
    if (childId == null) return null;
    final r = await _repo.subjectProgress(childId, subjectId);
    return r.fold((_) => null, (p) => p);
  }

  /// Weak topics for the selected child in [subjectId].
  Future<List<ChildWeakTopic>> weakTopics(String subjectId) async {
    final childId = state.selectedChildId;
    if (childId == null) return const [];
    final r = await _repo.weakTopics(childId, subjectId);
    return r.getOrElse(() => const []);
  }

  /// Parent self-service: unlinks a child and refreshes the children list.
  Future<bool> unlinkChild(String studentId) async {
    final r = await _repo.unlinkChild(studentId);
    return r.fold((_) => false, (_) {
      emit(state.copyWith(
          children: state.children.where((c) => c.id != studentId).toList()));
      return true;
    });
  }
}
