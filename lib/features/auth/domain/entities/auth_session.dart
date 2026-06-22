import 'package:equatable/equatable.dart';

/// Result of a successful authentication: the JWT plus the role hint the
/// backend returns alongside it (used to seed the first redirect before the
/// full profile loads).
class AuthSession extends Equatable {
  const AuthSession({required this.token, this.accountType});

  final String token;
  final String? accountType;

  @override
  List<Object?> get props => [token, accountType];
}
