import 'package:equatable/equatable.dart';

/// Captures the multi-step signup form. The OTP is filled in the email
/// verification step. Account creation is always an explicit user action.
class SignupData extends Equatable {
  const SignupData({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.otp = '',
    this.accountType = 'Student',
    this.marketingOptIn = false,
  });

  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String otp;
  final String accountType;
  final bool marketingOptIn;

  static const int minPasswordLength = 6;

  bool get passwordsMatch => password == confirmPassword;
  bool get isPasswordValid => password.length >= minPasswordLength;

  SignupData copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? otp,
    String? accountType,
    bool? marketingOptIn,
  }) {
    return SignupData(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      otp: otp ?? this.otp,
      accountType: accountType ?? this.accountType,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
    );
  }

  @override
  List<Object?> get props =>
      [name, email, password, confirmPassword, otp, accountType, marketingOptIn];
}
