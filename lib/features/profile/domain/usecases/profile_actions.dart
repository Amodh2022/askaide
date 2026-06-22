import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

/// Smaller profile mutations grouped in one file to avoid one-line use-case
/// files, while each keeps its own single-responsibility class.

class UpdateDisplayPicture implements UseCase<String, String> {
  UpdateDisplayPicture(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, String>> call(String filePath) =>
      _repository.updateDisplayPicture(filePath);
}

class DeleteProfilePhoto implements UseCase<Unit, NoParams> {
  DeleteProfilePhoto(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.deleteProfilePhoto();
}

class DeleteProfile implements UseCase<Unit, NoParams> {
  DeleteProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.deleteProfile();
}

class ChangePassword implements UseCase<Unit, ChangePasswordParams> {
  ChangePassword(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ChangePasswordParams params) =>
      _repository.changePassword(params.oldPassword, params.newPassword);
}

class ChangePasswordParams extends Equatable {
  const ChangePasswordParams({
    required this.oldPassword,
    required this.newPassword,
  });
  final String oldPassword;
  final String newPassword;
  @override
  List<Object?> get props => [oldPassword, newPassword];
}
