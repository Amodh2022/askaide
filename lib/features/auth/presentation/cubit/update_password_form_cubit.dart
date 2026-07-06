import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/validation/field_validators.dart';
import '../bloc/auth_bloc.dart';

class UpdatePasswordFormState extends Equatable {
  const UpdatePasswordFormState({
    this.showPassword = false,
    this.showConfirm = false,
  });

  final bool showPassword;
  final bool showConfirm;

  UpdatePasswordFormState copyWith({bool? showPassword, bool? showConfirm}) =>
      UpdatePasswordFormState(
        showPassword: showPassword ?? this.showPassword,
        showConfirm: showConfirm ?? this.showConfirm,
      );

  @override
  List<Object?> get props => [showPassword, showConfirm];
}

/// Owns the `/update-password/:id` password + confirm controllers and the
/// show/hide toggles. Dispatches the reset to [AuthBloc].
class UpdatePasswordFormCubit extends Cubit<UpdatePasswordFormState> {
  UpdatePasswordFormCubit(this._authBloc)
      : password = TextEditingController(),
        confirm = TextEditingController(),
        super(const UpdatePasswordFormState());

  final AuthBloc _authBloc;
  final TextEditingController password;
  final TextEditingController confirm;

  bool get match =>
      password.text.isNotEmpty && confirm.text.isNotEmpty && password.text == confirm.text;
  bool get conflict => confirm.text.isNotEmpty && password.text != confirm.text;

  void toggleShowPassword() =>
      emit(state.copyWith(showPassword: !state.showPassword));

  void toggleShowConfirm() =>
      emit(state.copyWith(showConfirm: !state.showConfirm));

  void submit(String token) {
    if (validateField(password.text, const [RequiredValidator()]) != null) {
      return;
    }
    if (validateField(confirm.text, const [RequiredValidator()]) != null) {
      return;
    }
    _authBloc.add(AuthResetPasswordSubmitted(
      password: password.text,
      confirmPassword: confirm.text,
      token: token,
    ));
  }

  @override
  Future<void> close() {
    password.dispose();
    confirm.dispose();
    return super.close();
  }
}
