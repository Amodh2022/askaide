import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/api_helpers.dart';
import '../../../core/network/endpoints.dart';

/// Public, unauthenticated platform stats that feed the landing-page live
/// counters (mirrors React `statsApi.getPublicStats`).
/// Live shape: `{ data: { totalStudents, totalSessions, totalQuestionsAnswered } }`.
class PublicStats extends Equatable {
  const PublicStats({
    this.totalStudents = 0,
    this.totalSessions = 0,
    this.totalQuestionsAnswered = 0,
  });

  final int totalStudents;
  final int totalSessions;
  final int totalQuestionsAnswered;

  factory PublicStats.fromJson(Map<dynamic, dynamic> j) => PublicStats(
        totalStudents: j.intval(['totalStudents']),
        totalSessions: j.intval(['totalSessions']),
        totalQuestionsAnswered: j.intval(['totalQuestionsAnswered']),
      );

  @override
  List<Object?> get props => [totalStudents, totalSessions, totalQuestionsAnswered];
}

abstract class PublicStatsRepository {
  Future<Either<Failure, PublicStats>> fetch();
}

class PublicStatsRepositoryImpl implements PublicStatsRepository {
  PublicStatsRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<Either<Failure, PublicStats>> fetch() => guardEither(() async {
        final res = await _dio.get(Endpoints.publicStats);
        return PublicStats.fromJson(res.dataMap());
      });
}

enum StatsLoad { initial, loading, loaded, error }

class PublicStatsState extends Equatable {
  const PublicStatsState({
    this.status = StatsLoad.initial,
    this.stats = const PublicStats(),
  });
  final StatsLoad status;
  final PublicStats stats;

  PublicStatsState copyWith({StatsLoad? status, PublicStats? stats}) =>
      PublicStatsState(status: status ?? this.status, stats: stats ?? this.stats);

  @override
  List<Object?> get props => [status, stats];
}

class PublicStatsCubit extends Cubit<PublicStatsState> {
  PublicStatsCubit(this._repo) : super(const PublicStatsState());
  final PublicStatsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: StatsLoad.loading));
    final r = await _repo.fetch();
    r.fold(
      (_) => emit(state.copyWith(status: StatsLoad.error)),
      (s) => emit(state.copyWith(status: StatsLoad.loaded, stats: s)),
    );
  }
}
