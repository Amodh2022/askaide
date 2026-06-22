import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Implements the domain [ProfileRepository] by delegating to the remote data
/// source and translating exceptions → [Failure]s. This is the single place
/// where the messy outside world is mapped onto clean domain types.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

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
      if (inner is UnauthorizedException) {
        return Left(UnauthorizedFailure(inner.message));
      }
      if (inner is NetworkException) return Left(NetworkFailure(inner.message));
      if (inner is ServerException) {
        return Left(ServerFailure(inner.message, statusCode: inner.statusCode));
      }
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getUserDetails() =>
      _guard(() async => (await _remote.getUserDetails()).toEntity());

  @override
  Future<Either<Failure, User>> updateProfile(Map<String, dynamic> changes) =>
      _guard(() async => (await _remote.updateProfile(changes)).toEntity());

  @override
  Future<Either<Failure, String>> updateDisplayPicture(String filePath) =>
      _guard(() => _remote.updateDisplayPicture(filePath));

  @override
  Future<Either<Failure, Unit>> deleteProfilePhoto() =>
      _guard(() async {
        await _remote.deleteProfilePhoto();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteProfile() => _guard(() async {
        await _remote.deleteProfile();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> changePassword(
    String oldPassword,
    String newPassword,
  ) =>
      _guard(() async {
        await _remote.changePassword(oldPassword, newPassword);
        return unit;
      });
}
