import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Domain contract for profile operations. The data layer provides the
/// implementation; use cases and blocs depend only on this abstraction.
abstract class ProfileRepository {
  Future<Either<Failure, User>> getUserDetails();
  Future<Either<Failure, User>> updateProfile(Map<String, dynamic> changes);
  Future<Either<Failure, String>> updateDisplayPicture(String filePath);
  Future<Either<Failure, Unit>> deleteProfilePhoto();
  Future<Either<Failure, Unit>> deleteProfile();
  Future<Either<Failure, Unit>> changePassword(
    String oldPassword,
    String newPassword,
  );
}
