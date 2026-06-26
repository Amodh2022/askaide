import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../storage/local_storage_service.dart';

/// Synthesizes the app's UI sound effects and plays them.
///
/// Faithful port of the web client's `SoundContext` (Web Audio API): the same
/// frequencies, waveforms, and exponential gain envelopes, rendered to 16-bit
/// PCM WAV buffers once and replayed on demand via [audioplayers].
///
/// Honours the persisted [LocalStorageService.soundEnabled] flag — every
/// `play*` call is a no-op while sound is disabled.
class SoundService {
  SoundService(this._storage) {
    // Configure a global audio session so UI sounds actually play on mobile:
    //  - iOS `playback` ignores the hardware mute/ringer switch (without this,
    //    sounds are silent whenever the ringer is off); `mixWithOthers` keeps
    //    any background audio playing.
    //  - Android marks these as transient sonification cues that don't grab
    //    audio focus from music/podcasts.
    AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
      android: const AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));
  }

  final LocalStorageService _storage;
  AudioPlayer _player = AudioPlayer(playerId: 'askaide_sfx')
    ..setReleaseMode(ReleaseMode.stop);

  /// Guards against concurrent `_play` calls piling up on a stuck player.
  bool _busy = false;

  static const int _sampleRate = 44100;

  bool get enabled => _storage.soundEnabled;

  // Lazily-built, cached WAV byte buffers (synthesis is deterministic).
  final Map<String, Uint8List> _cache = {};

  /// Short sine blip — used for clicks and taps. (600 Hz, 50 ms)
  void playClick() => _play('click', _clickSamples);

  /// Rising sine sweep — used for switches/toggles. (800 → 1200 Hz, 100 ms)
  void playToggle() => _play('toggle', _toggleSamples);

  /// Ascending C–E–G arpeggio — success/confirmation chime.
  void playSuccess() => _play('success', _successSamples);

  /// Low sawtooth buzz — errors. (200 Hz, 200 ms)
  void playError() => _play('error', _errorSamples);

  /// Two-note rising chime — notifications.
  void playNotification() => _play('notification', _notificationSamples);

  Future<void> _play(String key, List<double> Function() build) async {
    if (!enabled || _busy) return;
    _busy = true;
    final bytes = _cache.putIfAbsent(key, () => _encodeWav(build()));
    try {
      await _player.stop();
      await _player
          .play(BytesSource(bytes, mimeType: 'audio/wav'))
          .timeout(const Duration(seconds: 3));
    } catch (e, st) {
      if (kDebugMode) debugPrint('SoundService._play($key) failed: $e\n$st');
      // The player is stuck — swap it out so the next sound starts clean.
      _player.dispose().ignore();
      _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    } finally {
      _busy = false;
    }
  }

  Future<void> dispose() => _player.dispose();

  // ---- Tone synthesis ----------------------------------------------------

  /// One oscillator voice contributing to a buffer.
  static List<double> _render(List<_Voice> voices) {
    final totalSec = voices
        .map((v) => v.startSec + v.durationSec)
        .reduce(math.max);
    final length = (totalSec * _sampleRate).ceil();
    final out = List<double>.filled(length, 0);

    for (final v in voices) {
      final start = (v.startSec * _sampleRate).floor();
      final count = (v.durationSec * _sampleRate).floor();
      var phase = 0.0; // normalized [0,1)
      for (var i = 0; i < count; i++) {
        final t = i / count; // 0..1 progress through this voice
        // Exponential frequency ramp (matches exponentialRampToValueAtTime).
        final freq = v.freqStart * math.pow(v.freqEnd / v.freqStart, t);
        // Exponential gain decay from the start gain → 0.01.
        final gain = v.gainStart * math.pow(_Voice.gainEnd / v.gainStart, t);
        final sample = v.waveform == _Wave.sine
            ? math.sin(2 * math.pi * phase)
            : (2 * phase - 1); // sawtooth
        final idx = start + i;
        if (idx < length) out[idx] += sample * gain;
        phase += freq / _sampleRate;
        if (phase >= 1.0) phase -= 1.0;
      }
    }
    return out;
  }

  static List<double> _clickSamples() => _render(const [
        _Voice(freqStart: 600, freqEnd: 600, durationSec: 0.05),
      ]);

  static List<double> _toggleSamples() => _render(const [
        _Voice(freqStart: 800, freqEnd: 1200, durationSec: 0.1),
      ]);

  static List<double> _successSamples() => _render([
        for (var i = 0; i < 3; i++)
          _Voice(
            freqStart: const [523.25, 659.25, 783.99][i],
            freqEnd: const [523.25, 659.25, 783.99][i],
            startSec: i * 0.1,
            durationSec: 0.15,
          ),
      ]);

  static List<double> _errorSamples() => _render(const [
        _Voice(
          freqStart: 200,
          freqEnd: 200,
          durationSec: 0.2,
          waveform: _Wave.sawtooth,
        ),
      ]);

  static List<double> _notificationSamples() => _render([
        for (var i = 0; i < 2; i++)
          _Voice(
            freqStart: const [880.0, 1100.0][i],
            freqEnd: const [880.0, 1100.0][i],
            startSec: i * 0.15,
            durationSec: 0.2,
            gainStart: 0.08,
          ),
      ]);

  /// Wraps mono float samples in a 16-bit PCM WAV container.
  static Uint8List _encodeWav(List<double> samples, {int sampleRate = _sampleRate}) {
    final dataSize = samples.length * 2;
    final b = BytesBuilder();
    void str(String s) => b.add(s.codeUnits);
    void u32(int v) =>
        b.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
    void u16(int v) => b.add([v & 0xff, (v >> 8) & 0xff]);

    str('RIFF');
    u32(36 + dataSize);
    str('WAVE');
    str('fmt ');
    u32(16); // fmt chunk size
    u16(1); // PCM
    u16(1); // mono
    u32(sampleRate);
    u32(sampleRate * 2); // byte rate (sampleRate * channels * bytesPerSample)
    u16(2); // block align
    u16(16); // bits per sample
    str('data');
    u32(dataSize);
    for (final s in samples) {
      final v = (s.clamp(-1.0, 1.0) * 32767).round();
      u16(v & 0xffff);
    }
    return b.toBytes();
  }
}

enum _Wave { sine, sawtooth }

class _Voice {
  const _Voice({
    required this.freqStart,
    required this.freqEnd,
    required this.durationSec,
    this.startSec = 0,
    this.gainStart = 0.1,
    this.waveform = _Wave.sine,
  });

  /// All voices decay to this gain (matches the web client's 0.01 floor).
  static const double gainEnd = 0.01;

  final double freqStart;
  final double freqEnd;
  final double durationSec;
  final double startSec;
  final double gainStart;
  final _Wave waveform;
}
