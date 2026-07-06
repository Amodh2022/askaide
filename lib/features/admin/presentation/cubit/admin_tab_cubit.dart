import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the admin dashboard's selected tab index plus the tab strip's scroll
/// controller and per-tab keys (used to auto-scroll the active tab into view).
class AdminTabCubit extends Cubit<int> {
  AdminTabCubit()
      : scrollController = ScrollController(),
        tabKeys = List.generate(10, (_) => GlobalKey()),
        super(0);

  final ScrollController scrollController;
  final List<GlobalKey> tabKeys;

  void select(int index) => emit(index);

  @override
  Future<void> close() {
    scrollController.dispose();
    return super.close();
  }
}
