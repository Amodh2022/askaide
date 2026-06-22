import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/local_storage_service.dart';

/// Owns the active [ThemeMode] and persists the choice. Drives the light/dark
/// toggle in the sidebar and public navbar.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage) : super(_restore(_storage));

  final LocalStorageService _storage;

  static ThemeMode _restore(LocalStorageService storage) {
    return switch (storage.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void toggle(Brightness current) {
    final next =
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    set(next);
  }

  void set(ThemeMode mode) {
    _storage.setThemeMode(mode.name);
    emit(mode);
  }
}
