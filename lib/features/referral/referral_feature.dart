import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/failures.dart';
import '../../core/network/api_helpers.dart';
import '../../core/network/endpoints.dart';

/// Self-contained referral + daily-goal feature: model, repository, and cubit.

class ReferralInfo extends Equatable {
  const ReferralInfo({
    this.code = '',
    this.redeemCount = 0,
    this.dailyGoal = 0,
  });

  final String code;
  final int redeemCount;
  final int dailyGoal;

  ReferralInfo copyWith({String? code, int? redeemCount, int? dailyGoal}) =>
      ReferralInfo(
        code: code ?? this.code,
        redeemCount: redeemCount ?? this.redeemCount,
        dailyGoal: dailyGoal ?? this.dailyGoal,
      );

  @override
  List<Object?> get props => [code, redeemCount, dailyGoal];
}

class ReferralRepository {
  ReferralRepository(this._dio);
  final Dio _dio;

  Future<Either<Failure, ReferralInfo>> load() => guardEither(() async {
        final res = await _dio.get(Endpoints.referralMyCode);
        final d = res.dataMap();
        var info = ReferralInfo(
          code: d.str(['code', 'referralCode']),
          redeemCount: d.intval(['redeemCount', 'referrals', 'totalReferrals']),
        );
        try {
          final g = await _dio.get(Endpoints.goals);
          info = info.copyWith(dailyGoal: g.dataMap().intval(['dailyGoal']));
        } catch (_) {}
        return info;
      });

  Future<Either<Failure, Unit>> setGoal(int dailyGoal) => guardEither(() async {
        await _dio.put(Endpoints.goals, data: {'dailyGoal': dailyGoal});
        return unit;
      });
}

enum ReferralStatus { initial, loading, loaded, error }

class ReferralState extends Equatable {
  const ReferralState({
    this.status = ReferralStatus.initial,
    this.info = const ReferralInfo(),
  });
  final ReferralStatus status;
  final ReferralInfo info;

  ReferralState copyWith({ReferralStatus? status, ReferralInfo? info}) =>
      ReferralState(status: status ?? this.status, info: info ?? this.info);

  @override
  List<Object?> get props => [status, info];
}

class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit(this._repo) : super(const ReferralState());
  final ReferralRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: ReferralStatus.loading));
    final r = await _repo.load();
    r.fold(
      (f) => emit(state.copyWith(status: ReferralStatus.error)),
      (info) => emit(state.copyWith(status: ReferralStatus.loaded, info: info)),
    );
  }
}
