import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the "continue your session" banner has been dismissed. One
/// instance per banner mount.
class ContinueBannerCubit extends Cubit<bool> {
  ContinueBannerCubit() : super(false);

  void dismiss() => emit(true);
}
