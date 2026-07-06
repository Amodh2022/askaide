import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Types out a fixed-length text character-by-character. State is the number
/// of characters currently revealed. One instance per question shown.
class TypewriterCubit extends Cubit<int> {
  TypewriterCubit(int textLength) : super(0) {
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (state >= textLength) {
        t.cancel();
        return;
      }
      emit(state + 1);
    });
  }

  late final Timer _timer;

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}
