import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Contract for non-sensitive persistence: structured collections (session
/// history, offline answer queue) and simple scalars (theme mode, sound flag).
/// Consumers depend on this abstraction so the backing store (Hive /
/// SharedPreferences) can be mocked in tests or swapped without churn.
///
/// Boxes are opened once in [init] during app bootstrap so synchronous reads
/// are safe everywhere afterwards.
abstract class LocalStorageService {
  /// Bootstraps the backing stores and returns a ready-to-use instance.
  static Future<LocalStorageService> init() => LocalStorageServiceImpl.init();

  // ---- Theme -------------------------------------------------------------
  String? get themeMode;
  Future<void> setThemeMode(String mode);

  // ---- Sound effects -----------------------------------------------------
  bool get soundEnabled;
  Future<void> setSoundEnabled(bool enabled);

  // ---- Session history ---------------------------------------------------
  List<Map<String, dynamic>> readSessionHistory();
  Future<void> upsertSession(String id, Map<String, dynamic> json);
  Future<void> deleteSession(String id);

  // ---- Offline answer queue ---------------------------------------------
  List<Map<String, dynamic>> readAnswerQueue();
  Future<void> enqueueAnswer(String key, Map<String, dynamic> json);
  Future<void> dequeueAnswers(Iterable<String> keys);
  Iterable<String> get answerQueueKeys;
  bool get hasQueuedAnswers;

  // ---- Generic KV --------------------------------------------------------
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> clearAll();
}

/// Hive + SharedPreferences implementation of [LocalStorageService].
class LocalStorageServiceImpl implements LocalStorageService {
  LocalStorageServiceImpl(this._prefs);

  final SharedPreferences _prefs;

  late final Box<String> _sessionBox;
  late final Box<String> _answerQueueBox;
  late final Box<String> _kvBox;

  static Future<LocalStorageServiceImpl> init() async {
    await Hive.initFlutter();
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageServiceImpl(prefs);
    service._sessionBox =
        await Hive.openBox<String>(AppConstants.boxSessionHistory);
    service._answerQueueBox =
        await Hive.openBox<String>(AppConstants.boxAnswerQueue);
    service._kvBox = await Hive.openBox<String>(AppConstants.boxKeyValue);
    return service;
  }

  // ---- Theme -------------------------------------------------------------
  @override
  String? get themeMode => _prefs.getString(AppConstants.kThemeMode);
  @override
  Future<void> setThemeMode(String mode) =>
      _prefs.setString(AppConstants.kThemeMode, mode);

  // ---- Sound effects (defaults to enabled, mirroring the web client) -----
  @override
  bool get soundEnabled => _prefs.getBool(AppConstants.kSoundEnabled) ?? true;
  @override
  Future<void> setSoundEnabled(bool enabled) =>
      _prefs.setBool(AppConstants.kSoundEnabled, enabled);

  // ---- Session history (list of JSON-encoded sessions) -------------------
  @override
  List<Map<String, dynamic>> readSessionHistory() {
    return _sessionBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<void> upsertSession(String id, Map<String, dynamic> json) =>
      _sessionBox.put(id, jsonEncode(json));

  @override
  Future<void> deleteSession(String id) => _sessionBox.delete(id);

  // ---- Offline answer queue ---------------------------------------------
  @override
  List<Map<String, dynamic>> readAnswerQueue() {
    return _answerQueueBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<void> enqueueAnswer(String key, Map<String, dynamic> json) =>
      _answerQueueBox.put(key, jsonEncode(json));

  @override
  Future<void> dequeueAnswers(Iterable<String> keys) =>
      _answerQueueBox.deleteAll(keys);

  @override
  Iterable<String> get answerQueueKeys => _answerQueueBox.keys.cast<String>();

  @override
  bool get hasQueuedAnswers => _answerQueueBox.isNotEmpty;

  // ---- Generic KV --------------------------------------------------------
  @override
  String? read(String key) => _kvBox.get(key);
  @override
  Future<void> write(String key, String value) => _kvBox.put(key, value);
  @override
  Future<void> clearAll() async {
    await _sessionBox.clear();
    await _answerQueueBox.clear();
    await _kvBox.clear();
  }
}
