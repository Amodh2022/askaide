import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Base contract for all use cases (the interactor pattern). A use case is a
/// single, named application action: `final result = await login(params)`.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Synchronous variant for pure local operations.
abstract class SyncUseCase<Type, Params> {
  Either<Failure, Type> call(Params params);
}

/// For use cases that take no arguments.
class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
