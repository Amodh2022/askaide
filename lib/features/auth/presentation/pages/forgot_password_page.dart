import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

/// `/forgot-password` — two states: request form, then an "email sent"
/// confirmation with a resend button. Wired to AuthPasswordResetRequested.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_email.text.trim().isEmpty) return;
    context.read<AuthBloc>().add(AuthPasswordResetRequested(_email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AuthScaffold(
      tag: 'ACCOUNT RECOVERY',
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, n) => p.action != n.action,
        listener: (context, state) {
          if (state.action == AuthAction.resetEmailSent) {
            setState(() => _emailSent = true);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Reset email sent successfully')));
          } else if (state.action == AuthAction.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Failed to send reset email')));
          }
        },
        builder: (context, state) {
          final busy = state.action == AuthAction.loading;
          return _emailSent ? _sentView(c, busy) : _formView(c, busy);
        },
      ),
    );
  }

  Widget _formView(AskAideColors c, bool busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthEyebrow('FORGOT PASSWORD'),
          const AuthHeading(lead: 'Reset your', emphasis: 'password.'),
          Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: Text("Enter your email and we'll send you a link to get back in.",
                style: AppTypography.bodyMedium(c.textMuted)),
          ),
          AuthField(
            label: 'EMAIL ADDRESS',
            controller: _email,
            hintText: 'you@school.in',
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          _darkPill(c, busy, 'Send reset link', _submit),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () => context.go(RoutePaths.login),
              child: Text('← Back to sign in', style: AppTypography.bodySmall(c.textMuted)),
            ),
          ),
        ],
      );

  Widget _sentView(AskAideColors c, bool busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthEyebrow('EMAIL SENT'),
          const AuthHeading(lead: 'Check your', emphasis: 'inbox.'),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text.rich(
              TextSpan(
                style: AppTypography.bodyMedium(c.textMuted),
                children: [
                  const TextSpan(text: 'We sent a reset link to '),
                  TextSpan(
                      text: _email.text.trim(),
                      style: AppTypography.bodyMedium(c.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const TextSpan(text: ". Check your spam if it doesn't arrive."),
                ],
              ),
            ),
          ),
          _darkPill(c, busy, 'Resend email', _submit, withArrow: false),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => context.go(RoutePaths.login),
              child: Text('← Back to sign in', style: AppTypography.bodySmall(c.textMuted)),
            ),
          ),
        ],
      );

  Widget _darkPill(AskAideColors c, bool busy, String label, VoidCallback onTap,
          {bool withArrow = true}) =>
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onTap,
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
                    Text(label, style: AppTypography.button(c.bgPrimary)),
                    if (withArrow) ...[
                      const SizedBox(width: 8),
                      Text('→', style: AppTypography.serifEmphasis(c.bgPrimary, size: 16)),
                    ],
                  ],
                ),
        ),
      );
}
