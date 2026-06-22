part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.errorMessage,
    this.isMutating = false,
  });

  final ProfileStatus status;
  final User? user;
  final String? errorMessage;
  final bool isMutating;

  bool get isAuthenticatedUser => user != null;
  AccountType? get role => user?.accountType;

  ProfileState copyWith({
    ProfileStatus? status,
    User? user,
    String? errorMessage,
    bool? isMutating,
    bool clearUser = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, isMutating];
}
