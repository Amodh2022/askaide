import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/dashboard_models.dart';
import '../../data/dashboard_repository.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data = const DashboardData(),
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardData data;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    String? errorMessage,
  }) =>
      DashboardState(
        status: status ?? this.status,
        data: data ?? this.data,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, data, errorMessage];
}

/// Loads dashboard stats (progress + streak) for the current user.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());

  final DashboardRepository _repository;

  Future<void> load(String userId) async {
    if (userId.isEmpty) return;
    emit(state.copyWith(status: DashboardStatus.loading));
    final result = await _repository.loadDashboard(userId);
    result.fold(
      (failure) => emit(state.copyWith(
          status: DashboardStatus.error, errorMessage: failure.message)),
      (data) => emit(state.copyWith(status: DashboardStatus.loaded, data: data)),
    );
  }
}
