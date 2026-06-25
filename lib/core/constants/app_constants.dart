import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide constants. The API base URL is resolved at runtime, preferring the
/// `.env` file (loaded in `main`), then a `--dart-define`, then a safe default.
///   .env →  API_BASE_URL=https://staging.example.com/api/v1
class AppConstants {
  AppConstants._();

  static const String appName = 'AskAide';

  static const String _defaultApiBaseUrl =
      'https://askaideaibackend.onrender.com/api/v1';

  /// Base URL for all API calls: `.env` → `--dart-define` → default.
  static String get apiBaseUrl {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return _defaultApiBaseUrl;
  }

  static const Duration httpTimeout = Duration(seconds: 30);

  // Secure-storage keys
  static const String kJwtToken = 'askaide_jwt_token';
  static const String kRefreshToken = 'askaide_refresh_token';

  // Hive box names
  static const String boxSessionHistory = 'session_history';
  static const String boxAnswerQueue = 'offline_answer_queue';
  static const String boxKeyValue = 'kv_store';

  // SharedPreferences keys
  static const String kThemeMode = 'theme_mode';
  static const String kSoundEnabled = 'sound_enabled';

  // Batch sizes for the study flow
  static const int questionBatchSize = 5;

  /// Answers are flushed to the server in batches of this size (mirrors the
  /// frontend's `BATCH_SIZE = 10` in QuestionPractice).
  static const int answerSubmitBatchSize = 10;

  /// How many times we retry a `failed` generation response before giving up
  /// (frontend `useQuestionPolling`: 3 attempts).
  static const int batchRetryLimit = 3;

  /// While the server is still AI-generating a batch (`generating`/empty-success
  /// response) we poll up to this many times before surfacing an error. With
  /// [questionGeneratingPollInterval] this is ~60s of waiting, matching the
  /// frontend's 20-attempt polling loop.
  static const int questionGeneratingPollLimit = 20;

  /// Delay between polls while a batch is still generating.
  static const Duration questionGeneratingPollInterval = Duration(seconds: 3);

  /// Delay before retrying after a `failed` generation response.
  static const Duration questionFailedRetryDelay = Duration(seconds: 3);
}
