import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/local_storage_service.dart';
import 'sound_service.dart';

/// Owns the "sound effects enabled" flag and exposes the [SoundService] play
/// methods, mirroring the web client's `SoundContext`. State is the boolean
/// enabled flag so widgets (e.g. the Settings toggle) rebuild on change.
class SoundCubit extends Cubit<bool> {
  SoundCubit(this._storage, this._service) : super(_storage.soundEnabled);

  final LocalStorageService _storage;
  final SoundService _service;

  bool get enabled => state;

  Future<void> setEnabled(bool value) async {
    await _storage.setSoundEnabled(value);
    emit(value);
    // Confirm activation with a short chime, like the web client.
    if (value) _service.playToggle();
  }

  void playClick() => _service.playClick();
  void playToggle() => _service.playToggle();
  void playSuccess() => _service.playSuccess();
  void playError() => _service.playError();
  void playNotification() => _service.playNotification();

  @override
  Future<void> close() {
    _service.dispose();
    return super.close();
  }
}
