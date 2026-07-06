import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Cycles through the "generating questions" status messages on a timer.
/// State is the current message index. One instance per [_GeneratingView]
/// mount, so the random starting message still feels fresh on each show.
class GeneratingMessageCubit extends Cubit<int> {
  GeneratingMessageCubit(this._messageCount)
      : super(DateTime.now().millisecondsSinceEpoch % _messageCount) {
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => emit((state + 1) % _messageCount),
    );
  }

  final int _messageCount;
  late final Timer _timer;

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}
