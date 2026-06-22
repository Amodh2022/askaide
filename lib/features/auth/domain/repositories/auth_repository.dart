import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
import '../entities/signup_data.dart';

/// Domain contract for authentication. Implementations own JWT persistence so
/// callers never touch storage directly.
abstract class AuthRepository {
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  });

  /// Sends the email-verification OTP. Does NOT create an account.
  Future<Either<Failure, Unit>> sendOtp(String email);

  Future<Either<Failure, AuthSession>> signup(SignupData data);

  /// Requests a password-reset token/email for the address.
  Future<Either<Failure, Unit>> requestPasswordReset(String email);

  /// Completes a password reset using the token from the email link.
  Future<Either<Failure, Unit>> resetPassword({
    required String password,
    required String confirmPassword,
    required String token,
  });

  Future<Either<Failure, Unit>> logout();

  /// Reads any persisted JWT (app cold-start session restore).
  Future<String?> cachedToken();
}
