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
        id: j.str(['_id', 'id']),
        name: j.str(['name', 'childName'], 'Child'),
        grade: j.str(['grade', 'className']),
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
        streakDays: j.intval(['streakDays', 'currentStreak']),
        overallMastery: () {
          final v = j.dbl(['overallMastery', 'mastery']);
          return v > 1 ? v / 100 : v;
        }(),
      );

  @override
  List<Object?> get props => [childName, streakDays, overallMastery];
}

class ParentRepository {
  ParentRepository(this._dio);
  final Dio _dio;

  Future<Either<Failure, List<Child>>> children() => guardEither(() async {
        final res = await _dio.get(Endpoints.parentChildren);
        return res.dataList(['children']).whereType<Map>().map(Child.fromJson).toList();
      });

  Future<Either<Failure, ChildOverview>> overview(String childId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.parentChildOverview(childId));
        return ChildOverview.fromJson(res.dataMap());
      });
}

enum PLoad { initial, loading, loaded, error }

class ParentState extends Equatable {
  const ParentState({
    this.status = PLoad.initial,
    this.children = const [],
    this.overview,
    this.error,
  });
  final PLoad status;
  final List<Child> children;
  final ChildOverview? overview;
  final String? error;

  ParentState copyWith({
    PLoad? status,
    List<Child>? children,
    ChildOverview? overview,
    String? error,
  }) =>
      ParentState(
        status: status ?? this.status,
        children: children ?? this.children,
        overview: overview ?? this.overview,
        error: error,
      );

  @override
  List<Object?> get props => [status, children, overview, error];
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
        if (children.isNotEmpty) {
          final ov = await _repo.overview(children.first.id);
          ov.fold((_) {}, (o) => emit(state.copyWith(overview: o)));
        }
      },
    );
  }
}
