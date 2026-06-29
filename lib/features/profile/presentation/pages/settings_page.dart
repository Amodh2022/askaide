import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/widgets/confirm_dialog.dart';
import '../../../../core/presentation/widgets/page_scroll_scaffold.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/sound/sound_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/profile_cubit.dart';

/// `/settings` — Account, Appearance (theme), Sound effects, and Account
/// Actions (logout). Mirrors the web client's Settings page, including the
/// synthesized UI sound effects.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.select<ProfileCubit, dynamic>((p) => p.state.user);
    final sound = context.read<SoundCubit>();

    return PageScrollScaffold(
      maxWidth: 720,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
              // Header
              Text('— SETTINGS', style: AppTypography.sectionLabel(c.accent)),
              const SizedBox(height: AppSpacing.xs),
              Text('Preferences',
                  style: AppTypography.h1(c.textPrimary).copyWith(fontSize: 36)),
              const SizedBox(height: 6),
              Text('Customize your learning experience',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(height: AppSpacing.lg),

              // Account
              _Section(
                label: '— Account',
                icon: LucideIcons.user,
                title: 'Account',
                subtitle: 'Your account information',
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.bgRaised,
                        border: Border.all(color: c.border),
                        borderRadius: AppRadii.cardR,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: c.accent,
                            child: Text(
                              user?.initials ?? 'U',
                              style: AppTypography.labelLarge(c.bgCard),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.name ?? 'User',
                                    style: AppTypography.bodyLarge(c.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                                Text(user?.email ?? 'No email',
                                    style: AppTypography.bodySmall(c.textMuted),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.accentLight,
                              borderRadius: AppRadii.pillR,
                            ),
                            child: Text(user?.accountType.label ?? 'Student',
                                style: AppTypography.mono(c.accent, size: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _RowButton(
                      label: 'View Profile',
                      onTap: () {
                        sound.playClick();
                        context.push(RoutePaths.profile);
                      },
                    ),
                  ],
                ),
              ),

              // Appearance
              _Section(
                label: '— Appearance',
                icon: LucideIcons.palette,
                title: 'Appearance',
                subtitle: 'Choose your preferred theme',
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeOption(
                        icon: LucideIcons.sun,
                        label: 'Light',
                        description: 'Bright and clean',
                        selected: !isDark,
                        onTap: () {
                          sound.playClick();
                          context.read<ThemeCubit>().set(ThemeMode.light);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ThemeOption(
                        icon: LucideIcons.moon,
                        label: 'Dark',
                        description: 'Easy on the eyes',
                        selected: isDark,
                        onTap: () {
                          sound.playClick();
                          context.read<ThemeCubit>().set(ThemeMode.dark);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Sound
              _Section(
                label: '— Sound',
                icon: LucideIcons.volume2,
                title: 'Sound Effects',
                subtitle: 'Audio feedback for interactions',
                child: BlocBuilder<SoundCubit, bool>(
                  builder: (context, soundEnabled) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.bgRaised,
                            border: Border.all(color: c.border),
                            borderRadius: AppRadii.cardR,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Enable Sounds',
                                        style: AppTypography.bodyLarge(
                                            c.textPrimary)),
                                    Text('Play sounds for navigation & actions',
                                        style: AppTypography.bodySmall(
                                            c.textMuted)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: soundEnabled,
                                activeColor: c.accent,
                                onChanged: (v) => sound.setEnabled(v),
                              ),
                            ],
                          ),
                        ),
                        if (soundEnabled) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: c.bgRaised,
                              border: Border.all(color: c.border),
                              borderRadius: AppRadii.cardR,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TEST SOUNDS',
                                    style: AppTypography.sectionLabel(
                                        c.textMuted)),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _TestChip(
                                        label: 'Click', onTap: sound.playClick),
                                    _TestChip(
                                        label: 'Toggle', onTap: sound.playToggle),
                                    _TestChip(
                                        label: 'Success',
                                        onTap: sound.playSuccess),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Account Actions
              _Section(
                label: '— Session',
                icon: LucideIcons.logOut,
                title: 'Account Actions',
                subtitle: 'Manage your session',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      sound.playClick();
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Sign out',
                        message: 'Do you want to sign out?',
                        confirmLabel: 'Sign Out',
                        destructive: true,
                      );
                      if (!confirmed || !context.mounted) return;
                      context.read<ProfileCubit>().clear();
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                      context.go(RoutePaths.login);
                    },
                    icon: Icon(LucideIcons.logOut, size: 18, color: c.danger),
                    label: Text('Sign Out', style: AppTypography.button(c.danger)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),

              // App info footer
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Column(
                  children: [
                    Text('ASKAIDE · V1.0.0',
                        style: AppTypography.sectionLabel(c.textMuted)),
                    const SizedBox(height: 6),
                    Text('Built for Indian classrooms',
                        style: AppTypography.bodySmall(c.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String label;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.sectionLabel(c.textMuted)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  border: Border.all(color: c.border),
                  borderRadius: AppRadii.cardR,
                ),
                child: Icon(icon, size: 20, color: c.accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.h4(c.textPrimary)
                            .copyWith(fontSize: 18)),
                    Text(subtitle, style: AppTypography.bodySmall(c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardR,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? c.accentLight : c.bgRaised,
          border: Border.all(
              color: selected ? c.accent : c.border, width: selected ? 1.5 : 1),
          borderRadius: AppRadii.cardR,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? c.accent : c.bgCard,
                border: Border.all(color: c.border),
                borderRadius: AppRadii.cardR,
              ),
              child: Icon(icon, size: 22, color: selected ? c.bgCard : c.accent),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: AppTypography.labelLarge(
                        selected ? c.accent : c.textPrimary)
                    .copyWith(fontSize: 15)),
            Text(description,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(c.textMuted)),
            if (selected) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: AppRadii.pillR,
                ),
                child: Text('ACTIVE', style: AppTypography.mono(c.bgCard, size: 9)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RowButton extends StatelessWidget {
  const _RowButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardR,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.bgRaised,
          border: Border.all(color: c.border),
          borderRadius: AppRadii.cardR,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelLarge(c.textPrimary)),
            Icon(LucideIcons.chevronRight, size: 18, color: c.accent),
          ],
        ),
      ),
    );
  }
}

class _TestChip extends StatelessWidget {
  const _TestChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pillR,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: AppRadii.pillR,
        ),
        child: Text(label, style: AppTypography.button(c.bgCard)),
      ),
    );
  }
}
