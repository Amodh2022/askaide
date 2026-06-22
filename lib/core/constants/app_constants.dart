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

  // Hive box names
  static const String boxSessionHistory = 'session_history';
  static const String boxAnswerQueue = 'offline_answer_queue';
  static const String boxKeyValue = 'kv_store';

  // SharedPreferences keys
  static const String kThemeMode = 'theme_mode';

  // Batch sizes for the study flow
  static const int questionBatchSize = 5;
  static const int answerSubmitBatchSize = 5;
  static const int batchRetryLimit = 3;
}
