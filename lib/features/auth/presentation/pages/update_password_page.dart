import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/presentation/widgets/btn_spinner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/update_password_form_cubit.dart';

/// `/update-password/:id` — completes a password reset. Two-column on desktop
/// (branding + form card), single card on mobile. Token comes from the path.
class UpdatePasswordPage extends StatelessWidget {
  const UpdatePasswordPage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UpdatePasswordFormCubit>(
      create: (_) => sl<UpdatePasswordFormCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<UpdatePasswordFormCubit>();
    return Scaffold(
      backgroundColor: c.bgPrimary,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (p, n) => p.action != n.action,
        listener: (context, state) {
          if (state.action == AuthAction.passwordReset) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully')));
            context.go(RoutePaths.login);
          } else if (state.action == AuthAction.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Failed to update password')));
          }
        },
        builder: (context, state) {
          final busy = state.action == AuthAction.loading;
          final form = BlocBuilder<UpdatePasswordFormCubit, UpdatePasswordFormState>(
            builder: (context, formState) => AnimatedBuilder(
              animation: Listenable.merge([cubit.password, cubit.confirm]),
              builder: (context, _) => _FormCard(
                password: cubit.password,
                confirm: cubit.confirm,
                showPassword: formState.showPassword,
                showConfirm: formState.showConfirm,
                match: cubit.match,
                conflict: cubit.conflict,
                busy: busy,
                onTogglePassword: cubit.toggleShowPassword,
                onToggleConfirm: cubit.toggleShowConfirm,
                onSubmit: () => cubit.submit(token),
              ),
            ),
          );

          if (context.isDesktop) {
            return Row(
              children: [
                Expanded(child: _BrandingColumn()),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: form,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandingColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: AppRadii.pillR,
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 16, color: c.accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Secure Password Reset',
                        style: AppTypography.labelLarge(c.accent).copyWith(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('AskAide AI', style: AppTypography.h1(c.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Text('Create a strong password to keep your account secure',
                  style: AppTypography.bodyLarge(c.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.password,
    required this.confirm,
    required this.showPassword,
    required this.showConfirm,
    required this.match,
    required this.conflict,
    required this.busy,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  final TextEditingController password;
  final TextEditingController confirm;
  final bool showPassword;
  final bool showConfirm;
  final bool match;
  final bool conflict;
  final bool busy;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.go(RoutePaths.landing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.arrowLeft, size: 16, color: c.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text('Back to Home', style: AppTypography.labelLarge(c.textMuted).copyWith(fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: c.bgCard,
            borderRadius: AppRadii.modalR,
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.accent, Color.alphaBlend(Colors.black.withValues(alpha: 0.3), c.accent)],
                    ),
                    borderRadius: AppRadii.modalR,
                  ),
                  child: const Icon(LucideIcons.lock, size: 28, color: Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Create New Password',
                  textAlign: TextAlign.center, style: AppTypography.h3(c.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text('Almost done! Enter your new password below',
                  textAlign: TextAlign.center, style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(height: AppSpacing.lg),
              _field(c, 'New Password', password, showPassword, onTogglePassword, 'Enter new password'),
              const SizedBox(height: 20),
              _field(c, 'Confirm Password', confirm, showConfirm, onToggleConfirm, 'Re-enter password'),
              if (match || conflict) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(match ? LucideIcons.circleCheck : LucideIcons.circleX,
                        size: 14, color: match ? c.success : c.danger),
                    const SizedBox(width: 6),
                    Text(match ? 'Passwords match' : 'Passwords do not match',
                        style: AppTypography.bodySmall(match ? c.success : c.danger).copyWith(fontSize: 12)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: busy
                      ? const BtnSpinner(size: 16)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Reset Password', style: AppTypography.button(Colors.white)),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: GestureDetector(
                  onTap: () => context.go(RoutePaths.login),
                  child: Text('Back to Login', style: AppTypography.bodySmall(c.accent)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(AskAideColors c, String label, TextEditingController controller, bool show,
      VoidCallback onToggle, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLarge(c.textSecondary).copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !show,
          style: AppTypography.bodyLarge(c.textPrimary),
          cursorColor: c.accent,
          decoration: InputDecoration(
            filled: true,
            fillColor: c.bgRaised,
            hintText: hint,
            hintStyle: AppTypography.bodyMedium(c.textMuted),
            prefixIcon: Icon(LucideIcons.lock, size: 18, color: c.textMuted),
            suffixIcon: IconButton(
              icon: Icon(show ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: c.textMuted),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: _border(c.border),
            focusedBorder: _border(c.accent),
            border: _border(c.border),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: AppRadii.componentR,
        borderSide: BorderSide(color: color),
      );
}
