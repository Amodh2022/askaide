import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Coordinates the remote auth API with secure JWT persistence. On successful
/// login/signup the token is written to secure storage before returning.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SecureStorageService storage,
  })  : _remote = remote,
        _storage = storage;

  final AuthRemoteDataSource _remote;
  final SecureStorageService _storage;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      final inner = e.error;
      if (inner is ServerException) {
        return Left(ServerFailure(inner.message, statusCode: inner.statusCode));
      }
      if (inner is NetworkException) return Left(NetworkFailure(inner.message));
      if (inner is UnauthorizedException) {
        return Left(UnauthorizedFailure(inner.message));
      }
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final session = (await _remote.login(email, password)).toEntity();
        if (session.token.isEmpty) {
          throw ServerException('No token returned by server');
        }
        await _storage.writeToken(session.token);
        return session;
      });

  @override
  Future<Either<Failure, Unit>> sendOtp(String email) => _guard(() async {
        await _remote.sendOtp(email);
        return unit;
      });

  @override
  Future<Either<Failure, AuthSession>> signup(SignupData data) =>
      _guard(() async {
        final session = (await _remote.signup(data)).toEntity();
        if (session.token.isNotEmpty) {
          await _storage.writeToken(session.token);
        }
        return session;
      });

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) =>
      _guard(() async {
        await _remote.requestPasswordReset(email);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String password,
    required String confirmPassword,
    required String token,
  }) =>
      _guard(() async {
        await _remote.resetPassword(password, confirmPassword, token);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> logout() => _guard(() async {
        await _storage.deleteToken();
        return unit;
      });

  @override
  Future<String?> cachedToken() => _storage.readToken();
}
