import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/validation/field_validators.dart';
import '../bloc/auth_bloc.dart';

class LoginFormState extends Equatable {
  const LoginFormState({
    this.showPassword = false,
    this.keepSignedIn = true,
    this.googleLoading = false,
    this.emailError,
    this.passwordError,
  });

  final bool showPassword;
  final bool keepSignedIn;
  final bool googleLoading;
  final String? emailError;
  final String? passwordError;

  LoginFormState copyWith({
    bool? showPassword,
    bool? keepSignedIn,
    bool? googleLoading,
  }) =>
      LoginFormState(
        showPassword: showPassword ?? this.showPassword,
        keepSignedIn: keepSignedIn ?? this.keepSignedIn,
        googleLoading: googleLoading ?? this.googleLoading,
        emailError: emailError,
        passwordError: passwordError,
      );

  @override
  List<Object?> get props =>
      [showPassword, keepSignedIn, googleLoading, emailError, passwordError];
}

/// Owns the `/login` form: the email/password controllers, show-password and
/// keep-signed-in toggles, inline validation, and the Google sign-in flow.
/// Dispatches to [AuthBloc] for the actual login request.
class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit(this._authBloc)
      : email = TextEditingController(),
        password = TextEditingController(),
        super(const LoginFormState());

  final AuthBloc _authBloc;
  final TextEditingController email;
  final TextEditingController password;

  void toggleShowPassword() =>
      emit(state.copyWith(showPassword: !state.showPassword));

  void toggleKeepSignedIn() =>
      emit(state.copyWith(keepSignedIn: !state.keepSignedIn));

  void setKeepSignedIn(bool value) =>
      emit(state.copyWith(keepSignedIn: value));

  void submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final emailError = validateField(email.text.trim(),
        const [RequiredValidator('Email or username is required')]);
    final passwordError = validateField(
        password.text, const [RequiredValidator('Password is required')]);
    emit(LoginFormState(
      showPassword: state.showPassword,
      keepSignedIn: state.keepSignedIn,
      googleLoading: state.googleLoading,
      emailError: emailError,
      passwordError: passwordError,
    ));
    if (emailError != null || passwordError != null) return;
    _authBloc.add(
      AuthLoginRequested(email: email.text.trim(), password: password.text),
    );
  }

  Future<void> handleGoogleSignIn() async {
    emit(state.copyWith(googleLoading: true));
    try {
      final webClientId = AppConstants.googleClientId;
      final iosClientId = AppConstants.googleClientIdIos;

      debugPrint('[GoogleSignIn] platform: $defaultTargetPlatform');
      debugPrint('[GoogleSignIn] webClientId: ${webClientId.isNotEmpty ? webClientId : "(empty — check GOOGLE_CLIENT_ID in .env)"}');

      final String? platformClientId =
          defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isNotEmpty
              ? iosClientId
              : null;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('[GoogleSignIn] iOS clientId: ${platformClientId ?? "(none — will rely on GoogleService-Info.plist)"}');
      }

      // DIAGNOSTIC: try without serverClientId first to isolate whether the
      // issue is the Android client registration (error 10 without serverClientId)
      // or the web client ID cross-project mismatch (error 10 only with serverClientId).
      const testWithoutServerClientId = bool.fromEnvironment('GSI_NO_SERVER_ID');
      debugPrint('[GoogleSignIn] serverClientId mode: ${testWithoutServerClientId ? "DISABLED (diagnostic)" : "enabled"}');

      final googleSignIn = GoogleSignIn(
        clientId: platformClientId,
        serverClientId: (!testWithoutServerClientId && webClientId.isNotEmpty) ? webClientId : null,
      );

      debugPrint('[GoogleSignIn] calling signIn()...');
      final account = await googleSignIn.signIn();

      if (account == null) {
        debugPrint('[GoogleSignIn] signIn() returned null — user cancelled or sign-in was aborted');
        return;
      }

      debugPrint('[GoogleSignIn] account: ${account.email}, displayName: ${account.displayName}');

      final auth = await account.authentication;
      debugPrint('[GoogleSignIn] accessToken: ${auth.accessToken != null ? "present" : "null"}');
      debugPrint('[GoogleSignIn] idToken: ${auth.idToken != null ? "present (${auth.idToken!.length} chars)" : "NULL — serverClientId may be wrong or missing"}');

      final idToken = auth.idToken;
      if (idToken == null) {
        debugPrint('[GoogleSignIn] ERROR: idToken is null. The serverClientId must be a valid Web OAuth 2.0 client ID from Google Cloud Console.');
        _authBloc.add(const AuthGoogleLoginRequested(idToken: ''));
        return;
      }

      debugPrint('[GoogleSignIn] dispatching AuthGoogleLoginRequested...');
      _authBloc.add(AuthGoogleLoginRequested(idToken: idToken));
    } catch (e, st) {
      debugPrint('[GoogleSignIn] EXCEPTION: $e');
      debugPrint('[GoogleSignIn] STACKTRACE: $st');
      _authBloc.add(AuthGoogleLoginFailed(message: e.toString()));
    } finally {
      if (!isClosed) emit(state.copyWith(googleLoading: false));
    }
  }

  @override
  Future<void> close() {
    email.dispose();
    password.dispose();
    return super.close();
  }
}
