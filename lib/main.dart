import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/storage/local_storage_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// Bootstraps storage + DI, restores any persisted session, then runs the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment config (.env) before anything reads the API base URL.
  // Tolerate a missing file so the app still boots on its built-in default.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Open Hive boxes + SharedPreferences before anything reads them.
  final localStorage = await LocalStorageService.init();
  await configureDependencies(localStorage);

  // Cold-start: decide initial auth status from the persisted JWT.
  sl<AuthBloc>().add(const AuthCheckRequested());

  runApp(const AskAideApp());
}
