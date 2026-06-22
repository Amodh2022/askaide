import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session.dart';
import '../entities/signup_data.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class Login implements UseCase<AuthSession, LoginParams> {
  Login(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AuthSession>> call(LoginParams params) =>
      _repo.login(email: params.email, password: params.password);
}

class SendOtp implements UseCase<Unit, String> {
  SendOtp(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String email) => _repo.sendOtp(email);
}

class Signup implements UseCase<AuthSession, SignupData> {
  Signup(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AuthSession>> call(SignupData data) =>
      _repo.signup(data);
}

class RequestPasswordReset implements UseCase<Unit, String> {
  RequestPasswordReset(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String email) =>
      _repo.requestPasswordReset(email);
}

class ResetPasswordParams extends Equatable {
  const ResetPasswordParams({
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

class ResetPassword implements UseCase<Unit, ResetPasswordParams> {
  ResetPassword(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(ResetPasswordParams params) =>
      _repo.resetPassword(
        password: params.password,
        confirmPassword: params.confirmPassword,
        token: params.token,
      );
}

class Logout implements UseCase<Unit, NoParams> {
  Logout(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.logout();
}
