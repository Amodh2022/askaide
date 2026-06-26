part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Cold-start: restore any persisted JWT and decide initial auth status.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class AuthOtpRequested extends AuthEvent {
  const AuthOtpRequested(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class AuthSignupSubmitted extends AuthEvent {
  const AuthSignupSubmitted(this.data);
  final SignupData data;
  @override
  List<Object?> get props => [data];
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordSubmitted extends AuthEvent {
  const AuthResetPasswordSubmitted({
    required this.password,
    required this.confirmPassword,
    required this.token,
  });
  final String password;
  final String confirmPassword;
  final String token;
  @override
  List<Object?> get props => [password, confirmPassword, token];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested({required this.idToken});
  final String idToken;
  @override
  List<Object?> get props => [idToken];
}

/// Native Google Sign-In failed before reaching the backend (e.g. plugin
/// configuration error, no network, missing client ID). Distinct from a
/// server-side auth failure so the UI can show a meaningful message.
class AuthGoogleLoginFailed extends AuthEvent {
  const AuthGoogleLoginFailed({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Triggered by the network layer on a 401/403.
class AuthForcedLogout extends AuthEvent {
  const AuthForcedLogout();
}
