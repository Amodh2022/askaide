import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/signup_form_cubit.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

Color _strengthColor(AskAideColors c, int level) => switch (level) {
      1 => c.danger,
      2 => const Color(0xFFC68A3C),
      3 => const Color(0xFF8F7A2E),
      4 => c.accent,
      _ => c.textMuted,
    };

/// `/signup` — STEP 1/3. Collects name/email/password/confirm + a tips opt-in,
/// shows a live strength meter, then requests an OTP and advances to
/// /verify-email (passing the form via router `extra`).
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignupFormCubit>(
      create: (_) => sl<SignupFormCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<SignupFormCubit>();

    return AuthScaffold(
      tag: 'STEP 1 / 3',
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, n) => p.action != n.action,
        listener: (context, state) {
          if (state.action == AuthAction.otpSent && cubit.state.submitting) {
            cubit.clearSubmitting();
            context.go(RoutePaths.verifyEmail, extra: cubit.buildSignupData());
          } else if (state.action == AuthAction.failure) {
            cubit.clearSubmitting();
          }
        },
        builder: (context, state) {
          return BlocBuilder<SignupFormCubit, SignupFormState>(
            builder: (context, formState) {
          final busy = state.action == AuthAction.loading && formState.submitting;
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

              AuthField(label: 'YOUR NAME', controller: cubit.name, hintText: 'Aanya Sharma', errorText: formState.nameError),
              const SizedBox(height: 16),
              AuthField(
                label: 'EMAIL',
                controller: cubit.email,
                hintText: 'you@school.in',
                keyboardType: TextInputType.emailAddress,
                errorText: formState.emailError,
              ),
              const SizedBox(height: 16),
              AuthField(
                label: 'SET A PASSWORD',
                controller: cubit.password,
                hintText: 'Min. 6 characters',
                obscureText: !formState.showPassword,
                errorText: formState.passwordError,
                trailing: IconButton(
                  onPressed: cubit.toggleShowPassword,
                  icon: Icon(formState.showPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 18, color: c.textMuted),
                ),
              ),
              AnimatedBuilder(
                animation: cubit.password,
                builder: (context, _) {
                  final pwd = cubit.password.text;
                  if (pwd.isEmpty) return const SizedBox.shrink();
                  final strength = passwordStrengthOf(pwd);
                  final color = _strengthColor(c, strength.level);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: strength.level / 4,
                              minHeight: 2,
                              backgroundColor: c.border,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          child: Text(strength.label.toUpperCase(),
                              style: AppTypography.mono(color, size: 10)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              AuthField(
                label: 'CONFIRM PASSWORD',
                controller: cubit.confirm,
                hintText: 'Re-enter password',
                obscureText: !formState.showPassword,
                errorText: formState.confirmError,
                onSubmitted: (_) => cubit.submit(),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: cubit.toggleReceiveTips,
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: formState.receiveTips,
                        onChanged: (v) => cubit.setReceiveTips(v ?? false),
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
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.08),
                    border: Border.all(color: c.danger),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    state.errorMessage ?? 'Signup failed, please try again',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(c.danger),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : cubit.submit,
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
                            const SizedBox(width: 8),
                            Text('→', style: AppTypography.serifEmphasis(c.bgPrimary, size: 16)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
            ],
          );
            },
          );
        },
      ),
    );
  }
}
