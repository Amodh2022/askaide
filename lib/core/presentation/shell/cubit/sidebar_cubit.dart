import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the collapsible tablet-width sidebar is expanded. One instance per
/// [AppShell] mount — not app-global, so it's DI-registered as a factory.
class SidebarCubit extends Cubit<bool> {
  SidebarCubit() : super(true);

  void toggle() => emit(!state);
}
