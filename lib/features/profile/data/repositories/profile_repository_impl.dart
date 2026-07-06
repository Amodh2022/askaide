import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_helpers.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Implements the domain [ProfileRepository] by delegating to the remote data
/// source and translating exceptions → [Failure]s. This is the single place
/// where the messy outside world is mapped onto clean domain types.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, User>> getUserDetails() =>
      guardEither(() async => (await _remote.getUserDetails()).toEntity());

  @override
  Future<Either<Failure, User>> updateProfile(Map<String, dynamic> changes) =>
      guardEither(() async => (await _remote.updateProfile(changes)).toEntity());

  @override
  Future<Either<Failure, String>> updateDisplayPicture(String filePath) =>
      guardEither(() => _remote.updateDisplayPicture(filePath));

  @override
  Future<Either<Failure, Unit>> deleteProfilePhoto() =>
      guardEither(() async {
        await _remote.deleteProfilePhoto();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteProfile() => guardEither(() async {
        await _remote.deleteProfile();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> changePassword(
    String oldPassword,
    String newPassword,
  ) =>
      guardEither(() async {
        await _remote.changePassword(oldPassword, newPassword);
        return unit;
      });
}
