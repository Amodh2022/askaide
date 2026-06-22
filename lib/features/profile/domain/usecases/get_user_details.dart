import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/profile_repository.dart';

class GetUserDetails implements UseCase<User, NoParams> {
  GetUserDetails(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, User>> call(NoParams params) =>
      _repository.getUserDetails();
}
