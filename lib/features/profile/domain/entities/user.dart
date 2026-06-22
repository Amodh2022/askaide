import 'package:equatable/equatable.dart';

import 'account_type.dart';

/// Domain entity for the current user. Pure Dart (no JSON concerns) — the data
/// layer maps the API DTO into this.
class User extends Equatable {
  const User({
    required this.id,
    required this.firstName,
    required this.accountType,
    this.lastName,
    this.email,
    this.image,
    this.schoolId,
    this.className,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? image;
  final AccountType accountType;
  final String? schoolId;
  final String? className;

  /// Display name = first + last when present.
  String get name => [firstName, if (lastName != null) lastName].join(' ').trim();

  /// Initials for the avatar fallback.
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = (lastName?.isNotEmpty ?? false) ? lastName![0] : '';
    final result = (f + l).toUpperCase();
    return result.isEmpty ? 'U' : result;
  }

  @override
  List<Object?> get props =>
      [id, firstName, lastName, email, image, accountType, schoolId, className];
}
