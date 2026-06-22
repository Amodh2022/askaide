import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile implements UseCase<User, UpdateProfileParams> {
  UpdateProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) =>
      _repository.updateProfile(params.changes);
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams(this.changes);
  final Map<String, dynamic> changes;
  @override
  List<Object?> get props => [changes];
}
