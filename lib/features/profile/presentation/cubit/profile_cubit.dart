import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_user_details.dart';
import '../../domain/usecases/profile_actions.dart';
import '../../domain/usecases/update_profile.dart';

part 'profile_state.dart';

/// Holds the current [User]. Loaded after authentication; cleared on sign-out.
/// The router reads `state.role` to enforce role-gated routes.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetUserDetails getUserDetails,
    required UpdateProfile updateProfile,
    required ChangePassword changePassword,
  })  : _getUserDetails = getUserDetails,
        _updateProfile = updateProfile,
        _changePassword = changePassword,
        super(const ProfileState());

  final GetUserDetails _getUserDetails;
  final UpdateProfile _updateProfile;
  final ChangePassword _changePassword;

  Future<void> loadUser() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final result = await _getUserDetails(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(status: ProfileStatus.loaded, user: user)),
    );
  }

  Future<bool> updateProfile(Map<String, dynamic> changes) async {
    emit(state.copyWith(isMutating: true));
    final result = await _updateProfile(UpdateProfileParams(changes));
    return result.fold(
      (failure) {
        emit(state.copyWith(isMutating: false, errorMessage: failure.message));
        return false;
      },
      (user) {
        emit(state.copyWith(
          isMutating: false,
          status: ProfileStatus.loaded,
          user: user,
        ));
        return true;
      },
    );
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    emit(state.copyWith(isMutating: true));
    final result = await _changePassword(
      ChangePasswordParams(oldPassword: oldPassword, newPassword: newPassword),
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(isMutating: false, errorMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(isMutating: false));
        return true;
      },
    );
  }

  /// Called on sign-out to wipe the in-memory user.
  void clear() => emit(const ProfileState());
}
