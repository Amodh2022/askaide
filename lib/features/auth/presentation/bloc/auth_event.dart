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

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Triggered by the network layer on a 401/403.
class AuthForcedLogout extends AuthEvent {
  const AuthForcedLogout();
}
