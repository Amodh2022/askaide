import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the floating iOS bottom nav is visible. Hidden while scrolling
/// down, revealed while scrolling up. One instance per mobile shell mount.
class NavVisibilityCubit extends Cubit<bool> {
  NavVisibilityCubit() : super(true);

  void show() {
    if (!state) emit(true);
  }

  void hide() {
    if (state) emit(false);
  }
}
