import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/validation/field_validators.dart';
import '../bloc/auth_bloc.dart';

/// Owns the `/forgot-password` email controller and the request/sent toggle.
class ForgotPasswordFormCubit extends Cubit<bool> {
  ForgotPasswordFormCubit(this._authBloc)
      : email = TextEditingController(),
        super(false);

  final AuthBloc _authBloc;
  final TextEditingController email;

  bool get emailSent => state;

  void markEmailSent() => emit(true);

  void submit() {
    if (validateField(email.text.trim(), const [RequiredValidator()]) != null) {
      return;
    }
    _authBloc.add(AuthPasswordResetRequested(email.text.trim()));
  }

  @override
  Future<void> close() {
    email.dispose();
    return super.close();
  }
}
