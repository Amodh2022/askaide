import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/signup_data.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

/// `/verify-email` — STEP 2/3. Takes the [SignupData] gathered on the signup
/// screen (via router `extra`), collects the 6-digit OTP, and completes signup.
/// On success the auth status flips to authenticated → routed to /study.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, this.signupData});

  final SignupData? signupData;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _otp = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // No signup context → bounce back to /signup (mirrors the frontend guard).
    if (widget.signupData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(RoutePaths.signup);
      });
    }
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _submit() {
    final data = widget.signupData;
    if (data == null || _otp.text.trim().isEmpty) return;
    _submitting = true;
    context.read<AuthBloc>().add(AuthSignupSubmitted(data.copyWith(otp: _otp.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final email = widget.signupData?.email ?? '';

    return AuthScaffold(
      tag: 'STEP 2 / 3',
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, n) => p.status != n.status || p.action != n.action,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go(RoutePaths.study);
          } else if (state.action == AuthAction.none && _submitting) {
            // Account created but no token returned → sign in.
            _submitting = false;
            context.go(RoutePaths.login);
          } else if (state.action == AuthAction.failure) {
            _submitting = false;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Verification failed')));
          }
        },
        builder: (context, state) {
          final busy = state.action == AuthAction.loading;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthEyebrow('VERIFY EMAIL'),
              const AuthHeading(lead: 'Check your', emphasis: 'email.'),
              Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.bodyMedium(c.textMuted),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to '),
                      TextSpan(
                          text: email,
                          style: AppTypography.bodyMedium(c.textPrimary)
                              .copyWith(fontWeight: FontWeight.w600)),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              // Centered, wide-tracked mono OTP field.
              AuthField(
                label: 'VERIFICATION CODE',
                controller: _otp,
                hintText: '• • • • • •',
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.textPrimary,
                    foregroundColor: c.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.bgPrimary))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Verify & continue', style: AppTypography.button(c.bgPrimary)),
                            const SizedBox(width: 8),
                            Text('→', style: AppTypography.serifEmphasis(c.bgPrimary, size: 16)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => context.go(RoutePaths.signup),
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.bodySmall(c.textMuted),
                      children: [
                        const TextSpan(text: "Didn't receive it? "),
                        TextSpan(
                            text: 'Try again',
                            style: AppTypography.serifEmphasis(c.textPrimary, size: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
