import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns authentication status for the whole app. The router listens to this
/// bloc (via a refresh stream) and redirects on every status change.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required Login login,
    required LoginWithGoogle loginWithGoogle,
    required SendOtp sendOtp,
    required Signup signup,
    required RequestPasswordReset requestPasswordReset,
    required ResetPassword resetPassword,
    required Logout logout,
  })  : _repository = repository,
        _login = login,
        _loginWithGoogle = loginWithGoogle,
        _sendOtp = sendOtp,
        _signup = signup,
        _requestPasswordReset = requestPasswordReset,
        _resetPassword = resetPassword,
        _logout = logout,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
    on<AuthOtpRequested>(_onSendOtp);
    on<AuthSignupSubmitted>(_onSignup);
    on<AuthPasswordResetRequested>(_onRequestReset);
    on<AuthResetPasswordSubmitted>(_onResetPassword);
    on<AuthGoogleLoginFailed>(_onGoogleLoginFailed);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthForcedLogout>(_onForcedLogout);
  }

  final AuthRepository _repository;
  final Login _login;
  final LoginWithGoogle _loginWithGoogle;
  final SendOtp _sendOtp;
  final Signup _signup;
  final RequestPasswordReset _requestPasswordReset;
  final ResetPassword _resetPassword;
  final Logout _logout;

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final token = await _repository.cachedToken();
    if (token != null && token.isNotEmpty) {
      emit(state.copyWith(status: AuthStatus.authenticated, token: token));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(action: AuthAction.loading, clearError: true));
    final result = await _login(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(state.copyWith(
        action: AuthAction.failure,
        errorMessage: failure.message,
      )),
      (session) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        action: AuthAction.none,
        token: session.token,
        accountTypeHint: session.accountType,
      )),
    );
  }

  Future<void> _onGoogleLogin(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.idToken.isEmpty) {
      emit(state.copyWith(
        action: AuthAction.failure,
        errorMessage: 'Google sign-in did not return a valid token. '
            'Check your Google client configuration.',
      ));
      return;
    }
    emit(state.copyWith(action: AuthAction.loading, clearError: true));
    final result = await _loginWithGoogle(event.idToken);
    result.fold(
      (failure) => emit(state.copyWith(
        action: AuthAction.failure,
        errorMessage: failure.message,
      )),
      (session) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        action: AuthAction.none,
        token: session.token,
        accountTypeHint: session.accountType,
      )),
    );
  }

  void _onGoogleLoginFailed(
    AuthGoogleLoginFailed event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      action: AuthAction.failure,
      errorMessage: 'Google sign-in failed. Please try again.',
    ));
  }

  Future<void> _onSendOtp(AuthOtpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(action: AuthAction.loading, clearError: true));
    final result = await _sendOtp(event.email);
    result.fold(
      (failure) => emit(state.copyWith(
        action: AuthAction.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(action: AuthAction.otpSent)),
    );
  }

  Future<void> _onSignup(AuthSignupSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(action: AuthAction.loading, clearError: true));
    final result = await _signup(event.data);
    result.fold(
      (failure) => emit(state.copyWith(
        action: AuthAction.failure,
        errorMessage: failure.message,
      )),
      (session) {
        if (session.token.isNotEmpty) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            action: AuthAction.none,
            token: session.token,
            accountTypeHint: session.accountType,
          ));
        } else {
          // Account created but verification still required.
          emit(state.copyWith(action: AuthAction.none));
        }
      },
    );
  }

  Future<void> _onRequestReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(action: AuthAction.loading, clearError: true));
    final result = await _requestPasswordReset(event.email);
    result.fold(
      (failure) => emit(state.copyWith(
        action: AuthAction.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(action: AuthAction.resetEmailSent)),
    );
  }

  Future<void> _onResetPassword(
    AuthResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(action: AuthAction.loading, clearError: true));
    final result = await _resetPassword(
      ResetPasswordParams(
        password: event.password,
        confirmPassword: event.confirmPassword,
        token: event.token,
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(
        action: AuthAction.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(action: AuthAction.passwordReset)),
    );
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _logout(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onForcedLogout(
    AuthForcedLogout event,
    Emitter<AuthState> emit,
  ) async {
    await _logout(const NoParams());
    emit(const AuthState(
      status: AuthStatus.unauthenticated,
      action: AuthAction.failure,
      errorMessage: 'Your session expired. Please sign in again.',
    ));
  }
}
