import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/login_form_cubit.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

/// `/login` — mirrors the frontend Login screen: welcome eyebrow, "Sign in."
/// heading, email + password (with show/hide), keep-signed-in, error banner,
/// dark pill submit, disabled Google / School SSO, trust signal, signup link.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginFormCubit>(
      create: (_) => sl<LoginFormCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cubit = context.read<LoginFormCubit>();
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Suppress the form during the cold-start token check so it doesn't
        // flash before the router redirects authenticated users to /study.
        if (state.status == AuthStatus.unknown) return const Scaffold();

        final c = context.colors;
        final busy = state.action == AuthAction.loading;
        final failed = state.action == AuthAction.failure;

        return AuthScaffold(
          tag: 'SIGN IN',
          child: BlocBuilder<LoginFormCubit, LoginFormState>(
            builder: (context, formState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthEyebrow('WELCOME BACK'),
                const AuthHeading(lead: 'Sign', emphasis: 'in.'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Text(
                    'The next 10 minutes of practice are waiting.',
                    style: AppTypography.bodyMedium(c.textMuted),
                  ),
                ),

                AuthField(
                  label: 'EMAIL ADDRESS',
                  controller: cubit.email,
                  hintText: 'you@school.in',
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  errorText: formState.emailError,
                ),
                const SizedBox(height: 18),

                AuthField(
                  label: 'PASSWORD',
                  controller: cubit.password,
                  hintText: '••••••••',
                  obscureText: !formState.showPassword,
                  errorText: formState.passwordError,
                  onSubmitted: (_) => cubit.submit(),
                  trailingLabel: GestureDetector(
                    onTap: () => context.go(RoutePaths.forgotPassword),
                    child: Text('Forgot password?',
                        style: AppTypography.bodySmall(c.accent).copyWith(fontSize: 12)),
                  ),
                  trailing: IconButton(
                    onPressed: cubit.toggleShowPassword,
                    icon: Icon(formState.showPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 18, color: c.textMuted),
                    tooltip: formState.showPassword ? 'Hide password' : 'Show password',
                  ),
                ),
                const SizedBox(height: 18),

                // Keep me signed in
                GestureDetector(
                  onTap: cubit.toggleKeepSignedIn,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: formState.keepSignedIn,
                          onChanged: (v) => cubit.setKeepSignedIn(v ?? true),
                          activeColor: c.accent,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Keep me signed in',
                          style: AppTypography.bodySmall(c.textMuted)),
                    ],
                  ),
                ),

                if (failed) ...[
                  const SizedBox(height: 18),
                  _ErrorBanner(message: state.errorMessage),
                ],

                const SizedBox(height: 18),
                _SubmitButton(busy: busy, onPressed: busy ? null : cubit.submit),

                const SizedBox(height: 18),
                _SsoRow(
                  onGoogleTap: busy ? null : cubit.handleGoogleSignIn,
                  googleLoading: formState.googleLoading,
                ),

                const SizedBox(height: 18),
                Center(
                  child: Text('🔒 Your data is encrypted and secure',
                      style: AppTypography.bodySmall(c.textMuted).copyWith(fontSize: 12)),
                ),

                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go(RoutePaths.signup),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium(c.textPrimary)
                            .copyWith(fontWeight: FontWeight.w500),
                        children: [
                          const TextSpan(text: 'New to AskAide? Create an account '),
                          TextSpan(text: '→', style: AppTypography.serifEmphasis(c.textPrimary, size: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Inline error banner shown on a failed sign-in.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.08),
        border: Border.all(color: c.danger),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message?.isNotEmpty == true
                ? message!
                : "Couldn't sign in — check your email and password.",
            style: AppTypography.bodySmall(c.danger),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => context.go(RoutePaths.forgotPassword),
            child: Text('Forgot password?',
                style: AppTypography.bodySmall(c.danger).copyWith(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                )),
          ),
        ],
      ),
    );
  }
}

/// Full-width dark pill submit button with a serif arrow.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.busy, required this.onPressed});
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: busy ? c.textMuted : c.textPrimary,
          foregroundColor: c.bgPrimary,
          disabledBackgroundColor: c.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
        ),
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.bgPrimary),
                  ),
                  const SizedBox(width: 10),
                  Text('Signing in...', style: AppTypography.button(c.bgPrimary)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign in to your account', style: AppTypography.button(c.bgPrimary)),
                  const SizedBox(width: 8),
                  Text('→', style: AppTypography.serifEmphasis(c.bgPrimary, size: 16)),
                ],
              ),
      ),
    );
  }
}

/// Google Sign-In + School SSO row.
class _SsoRow extends StatelessWidget {
  const _SsoRow({required this.onGoogleTap, required this.googleLoading});

  final VoidCallback? onGoogleTap;
  final bool googleLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget btn({required Widget child, VoidCallback? onPressed}) => Expanded(
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
              foregroundColor: c.textPrimary,
              disabledForegroundColor: c.textMuted,
            ),
            child: child,
          ),
        );

    return Row(
      children: [
        btn(
          onPressed: onGoogleTap,
          child: googleLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('G',
                        style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 7),
                    Text('Continue with Google',
                        style: AppTypography.bodySmall(c.textPrimary)),
                  ],
                ),
        ),
        const SizedBox(width: 8),
        btn(child: Text('🏫 School SSO', style: AppTypography.bodySmall(c.textPrimary))),
      ],
    );
  }
}
