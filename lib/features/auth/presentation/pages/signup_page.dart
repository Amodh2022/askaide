import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/signup_data.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

/// Password-strength result mirroring the frontend's `getPasswordStrength`.
class _Strength {
  const _Strength(this.level, this.label, this.color);
  final int level;
  final String label;
  final Color color;
}

/// `/signup` — STEP 1/3. Collects name/email/password/confirm + a tips opt-in,
/// shows a live strength meter, then requests an OTP and advances to
/// /verify-email (passing the form via router `extra`).
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _receiveTips = false;
  String? _nameError, _emailError, _passwordError, _confirmError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  _Strength _strength(String pwd) {
    final c = context.colors;
    if (pwd.isEmpty) return _Strength(0, '', c.textMuted);
    var score = 0;
    if (pwd.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(pwd) && RegExp(r'[A-Z]').hasMatch(pwd)) score++;
    if (RegExp(r'\d').hasMatch(pwd)) score++;
    if (RegExp(r'''[!@#$%^&*(),.?":{}|<>]''').hasMatch(pwd)) score++;
    if (score <= 1) return _Strength(1, 'Weak', c.danger);
    if (score == 2) return const _Strength(2, 'Fair', Color(0xFFC68A3C));
    if (score == 3) return const _Strength(3, 'Good', Color(0xFF8F7A2E));
    return _Strength(4, 'Strong', c.accent);
  }

  void _submit() {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Full name is required' : null;
      _emailError = _email.text.trim().isEmpty ? 'Email is required' : null;
      _passwordError = _password.text.isEmpty
          ? 'Password is required'
          : (_password.text.length < 6 ? 'At least 6 characters' : null);
      _confirmError = _confirm.text.isEmpty
          ? 'Confirm your password'
          : (_confirm.text != _password.text ? 'Passwords do not match' : null);
    });
    if ([_nameError, _emailError, _passwordError, _confirmError].any((e) => e != null)) {
      return;
    }
    _submitting = true;
    // First step requests the OTP; the verify screen completes signup.
    context.read<AuthBloc>().add(AuthOtpRequested(_email.text.trim()));
  }

  SignupData get _data => SignupData(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        confirmPassword: _confirm.text,
        accountType: 'Student',
        marketingOptIn: _receiveTips,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pwd = _password.text;
    final strength = _strength(pwd);

    return AuthScaffold(
      tag: 'STEP 1 / 3',
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, n) => p.action != n.action,
        listener: (context, state) {
          if (state.action == AuthAction.otpSent && _submitting) {
            _submitting = false;
            context.go(RoutePaths.verifyEmail, extra: _data);
          } else if (state.action == AuthAction.failure) {
            _submitting = false;
          }
        },
        builder: (context, state) {
          final busy = state.action == AuthAction.loading && _submitting;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthEyebrow('ACCOUNT'),
              const AuthHeading(lead: 'Create', emphasis: 'account.'),
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Text('Three fields. No card, no spam.',
                    style: AppTypography.bodyMedium(c.textMuted)),
              ),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodySmall(c.textMuted),
                    children: [
                      const TextSpan(text: 'Join '),
                      TextSpan(
                        text: '10,000+',
                        style: AppTypography.bodySmall(c.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' students already learning smarter'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              AuthField(label: 'YOUR NAME', controller: _name, hintText: 'Aanya Sharma', errorText: _nameError),
              const SizedBox(height: AppSpacing.md),
              AuthField(
                label: 'EMAIL',
                controller: _email,
                hintText: 'you@school.in',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: AppSpacing.md),
              AuthField(
                label: 'SET A PASSWORD',
                controller: _password,
                hintText: 'Min. 6 characters',
                obscureText: !_showPassword,
                errorText: _passwordError,
                trailing: IconButton(
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 18, color: c.textMuted),
                ),
              ),
              if (pwd.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: strength.level / 4,
                          minHeight: 2,
                          backgroundColor: c.border,
                          valueColor: AlwaysStoppedAnimation(strength.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 44,
                      child: Text(strength.label.toUpperCase(),
                          style: AppTypography.mono(strength.color, size: 10)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AuthField(
                label: 'CONFIRM PASSWORD',
                controller: _confirm,
                hintText: 'Re-enter password',
                obscureText: !_showPassword,
                errorText: _confirmError,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),

              GestureDetector(
                onTap: () => setState(() => _receiveTips = !_receiveTips),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _receiveTips,
                        onChanged: (v) => setState(() => _receiveTips = v ?? false),
                        activeColor: c.accent,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('I want to receive study tips and motivation 🎯',
                          style: AppTypography.bodySmall(c.textMuted)),
                    ),
                  ],
                ),
              ),

              if (state.action == AuthAction.failure) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.08),
                    border: Border.all(color: c.danger),
                    borderRadius: AppRadii.cardR,
                  ),
                  child: Text(
                    state.errorMessage ?? 'Signup failed, please try again',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(c.danger),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: busy ? c.textMuted : c.textPrimary,
                    foregroundColor: c.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: busy
                      ? Text('Creating account...', style: AppTypography.button(c.bgPrimary))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Create account', style: AppTypography.button(c.bgPrimary)),
                            const SizedBox(width: AppSpacing.xs),
                            Text('→', style: AppTypography.serifEmphasis(c.bgPrimary, size: 16)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('By signing up, you agree to our ',
                        style: AppTypography.bodySmall(c.textMuted).copyWith(fontSize: 11)),
                    GestureDetector(
                      onTap: () => context.go(RoutePaths.termsOfService),
                      child: Text('Terms',
                          style: AppTypography.bodySmall(c.accent).copyWith(fontSize: 11)),
                    ),
                    Text(' and ', style: AppTypography.bodySmall(c.textMuted).copyWith(fontSize: 11)),
                    GestureDetector(
                      onTap: () => context.go(RoutePaths.privacyPolicy),
                      child: Text('Privacy Policy',
                          style: AppTypography.bodySmall(c.accent).copyWith(fontSize: 11)),
                    ),
                    Text('.', style: AppTypography.bodySmall(c.textMuted).copyWith(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: GestureDetector(
                  onTap: () => context.go(RoutePaths.login),
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.bodySmall(c.textMuted),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in',
                          style: AppTypography.serifEmphasis(c.textPrimary, size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          );
        },
      ),
    );
  }
}
