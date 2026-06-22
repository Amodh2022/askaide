part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// What the most recent async auth action is doing (drives button spinners and
/// transient banners without losing the stable [AuthStatus]).
enum AuthAction { none, loading, otpSent, resetEmailSent, passwordReset, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.action = AuthAction.none,
    this.token,
    this.accountTypeHint,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthAction action;
  final String? token;
  final String? accountTypeHint;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isBusy => action == AuthAction.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthAction? action,
    String? token,
    String? accountTypeHint,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      action: action ?? this.action,
      token: token ?? this.token,
      accountTypeHint: accountTypeHint ?? this.accountTypeHint,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, action, token, accountTypeHint, errorMessage];
}
