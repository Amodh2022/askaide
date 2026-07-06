import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/validation/field_validators.dart';
import '../../domain/entities/signup_data.dart';
import '../bloc/auth_bloc.dart';

class SignupFormState extends Equatable {
  const SignupFormState({
    this.showPassword = false,
    this.receiveTips = false,
    this.submitting = false,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmError,
  });

  final bool showPassword;
  final bool receiveTips;
  final bool submitting;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmError;

  SignupFormState copyWith({
    bool? showPassword,
    bool? receiveTips,
    bool? submitting,
  }) =>
      SignupFormState(
        showPassword: showPassword ?? this.showPassword,
        receiveTips: receiveTips ?? this.receiveTips,
        submitting: submitting ?? this.submitting,
        nameError: nameError,
        emailError: emailError,
        passwordError: passwordError,
        confirmError: confirmError,
      );

  @override
  List<Object?> get props => [
        showPassword,
        receiveTips,
        submitting,
        nameError,
        emailError,
        passwordError,
        confirmError,
      ];
}

/// Password-strength result mirroring the frontend's `getPasswordStrength`.
class PasswordStrength {
  const PasswordStrength(this.level, this.label);
  final int level;
  final String label;
}

PasswordStrength passwordStrengthOf(String pwd) {
  if (pwd.isEmpty) return const PasswordStrength(0, '');
  var score = 0;
  if (pwd.length >= 8) score++;
  if (RegExp(r'[a-z]').hasMatch(pwd) && RegExp(r'[A-Z]').hasMatch(pwd)) score++;
  if (RegExp(r'\d').hasMatch(pwd)) score++;
  if (RegExp(r'''[!@#$%^&*(),.?":{}|<>]''').hasMatch(pwd)) score++;
  if (score <= 1) return const PasswordStrength(1, 'Weak');
  if (score == 2) return const PasswordStrength(2, 'Fair');
  if (score == 3) return const PasswordStrength(3, 'Good');
  return const PasswordStrength(4, 'Strong');
}

/// Owns the `/signup` (step 1/3) form: name/email/password/confirm
/// controllers, show-password and tips-opt-in toggles, and validation.
/// Requests an OTP via [AuthBloc]; the verify screen completes signup.
class SignupFormCubit extends Cubit<SignupFormState> {
  SignupFormCubit(this._authBloc)
      : name = TextEditingController(),
        email = TextEditingController(),
        password = TextEditingController(),
        confirm = TextEditingController(),
        super(const SignupFormState());

  final AuthBloc _authBloc;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirm;

  void toggleShowPassword() =>
      emit(state.copyWith(showPassword: !state.showPassword));

  void toggleReceiveTips() =>
      emit(state.copyWith(receiveTips: !state.receiveTips));

  void setReceiveTips(bool value) => emit(state.copyWith(receiveTips: value));

  void submit() {
    final nameError = validateField(
        name.text.trim(), const [RequiredValidator('Full name is required')]);
    final emailError = validateField(
        email.text.trim(), const [RequiredValidator('Email is required')]);
    final passwordError = validateField(password.text, [
      const RequiredValidator('Password is required'),
      const MinLengthValidator(SignupData.minPasswordLength,
          message: 'At least ${SignupData.minPasswordLength} characters'),
    ]);
    final confirmError = validateField(confirm.text, [
      const RequiredValidator('Confirm your password'),
      MatchesValidator(() => password.text),
    ]);
    emit(SignupFormState(
      showPassword: state.showPassword,
      receiveTips: state.receiveTips,
      submitting: state.submitting,
      nameError: nameError,
      emailError: emailError,
      passwordError: passwordError,
      confirmError: confirmError,
    ));
    if ([nameError, emailError, passwordError, confirmError].any((e) => e != null)) {
      return;
    }
    emit(state.copyWith(submitting: true));
    // First step requests the OTP; the verify screen completes signup.
    _authBloc.add(AuthOtpRequested(email.text.trim()));
  }

  void clearSubmitting() => emit(state.copyWith(submitting: false));

  SignupData buildSignupData() => SignupData(
        name: name.text.trim(),
        email: email.text.trim(),
        password: password.text,
        confirmPassword: confirm.text,
        accountType: 'Student',
        marketingOptIn: state.receiveTips,
      );

  @override
  Future<void> close() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    return super.close();
  }
}
