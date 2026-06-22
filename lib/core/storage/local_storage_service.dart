import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Non-sensitive persistence: Hive for structured collections (session history,
/// offline answer queue) and SharedPreferences for simple scalars (theme mode).
///
/// Boxes are opened once in [init] during app bootstrap so synchronous reads
/// are safe everywhere afterwards.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  late final Box<String> _sessionBox;
  late final Box<String> _answerQueueBox;
  late final Box<String> _kvBox;

  static Future<LocalStorageService> init() async {
    await Hive.initFlutter();
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    service._sessionBox =
        await Hive.openBox<String>(AppConstants.boxSessionHistory);
    service._answerQueueBox =
        await Hive.openBox<String>(AppConstants.boxAnswerQueue);
    service._kvBox = await Hive.openBox<String>(AppConstants.boxKeyValue);
    return service;
  }

  // ---- Theme -------------------------------------------------------------
  String? get themeMode => _prefs.getString(AppConstants.kThemeMode);
  Future<void> setThemeMode(String mode) =>
      _prefs.setString(AppConstants.kThemeMode, mode);

  // ---- Session history (list of JSON-encoded sessions) -------------------
  List<Map<String, dynamic>> readSessionHistory() {
    return _sessionBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  Future<void> upsertSession(String id, Map<String, dynamic> json) =>
      _sessionBox.put(id, jsonEncode(json));

  Future<void> deleteSession(String id) => _sessionBox.delete(id);

  // ---- Offline answer queue ---------------------------------------------
  List<Map<String, dynamic>> readAnswerQueue() {
    return _answerQueueBox.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  Future<void> enqueueAnswer(String key, Map<String, dynamic> json) =>
      _answerQueueBox.put(key, jsonEncode(json));

  Future<void> dequeueAnswers(Iterable<String> keys) =>
      _answerQueueBox.deleteAll(keys);

  Iterable<String> get answerQueueKeys => _answerQueueBox.keys.cast<String>();

  bool get hasQueuedAnswers => _answerQueueBox.isNotEmpty;

  // ---- Generic KV --------------------------------------------------------
  String? read(String key) => _kvBox.get(key);
  Future<void> write(String key, String value) => _kvBox.put(key, value);
  Future<void> clearAll() async {
    await _sessionBox.clear();
    await _answerQueueBox.clear();
    await _kvBox.clear();
  }
}
