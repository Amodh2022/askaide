import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PracticeUiState extends Equatable {
  const PracticeUiState({this.streakMessage, this.streakExcellent = false});

  final String? streakMessage;
  final bool streakExcellent;

  @override
  List<Object?> get props => [streakMessage, streakExcellent];
}

/// Owns the transient streak badge (mirrors React's Variable Rewards) and the
/// end-of-session-flow guard for [PracticePanel]. One instance per panel mount.
class PracticeUiCubit extends Cubit<PracticeUiState> {
  PracticeUiCubit() : super(const PracticeUiState());

  int _prevStreak = 0;
  bool _resultShown = false;
  Timer? _streakTimer;

  bool get resultShown => _resultShown;
  void markResultShown() => _resultShown = true;
  void clearResultShown() => _resultShown = false;

  /// Only fires when the streak grows past a threshold (matches React).
  void handleStreak(int streak) {
    if (streak > _prevStreak && streak >= 3) {
      emit(streak >= 5
          ? const PracticeUiState(streakMessage: '🌟 Excellent streak!', streakExcellent: true)
          : const PracticeUiState(streakMessage: '🔥 On fire!', streakExcellent: false));
      _streakTimer?.cancel();
      _streakTimer = Timer(const Duration(milliseconds: 2500), () {
        if (!isClosed) emit(const PracticeUiState());
      });
    }
    _prevStreak = streak;
  }

  @override
  Future<void> close() {
    _streakTimer?.cancel();
    return super.close();
  }
}
