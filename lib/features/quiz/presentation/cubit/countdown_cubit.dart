import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives a count-down timer's 2Hz flash tick and fires [onExpire] exactly
/// once when the deadline passes. State is the alternating flash flag; the
/// widget recomputes the remaining duration fresh on every tick.
class CountdownCubit extends Cubit<bool> {
  CountdownCubit(DateTime deadline, VoidCallback onExpire) : super(false) {
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final remaining =
          deadline.difference(DateTime.now()).inSeconds.clamp(0, 1 << 31);
      if (remaining <= 0 && !_expired) {
        _expired = true;
        onExpire();
      }
      emit(!state);
    });
  }

  bool _expired = false;
  late final Timer _ticker;

  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }
}
