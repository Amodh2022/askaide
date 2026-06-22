import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/profile_cubit.dart';

/// `/settings` — Account, Appearance (theme), Sound, and a Danger Zone (logout).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.select<ProfileCubit, dynamic>((p) => p.state.user);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('— SETTINGS', style: AppTypography.sectionLabel(c.accent)),
              const SizedBox(height: 8),
              Text('Preferences', style: AppTypography.h1(c.textPrimary).copyWith(fontSize: 36)),
              const SizedBox(height: 24),

              // Account
              _Section(
                title: 'Account',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: c.accentLight,
                      child: Text(user?.initials ?? 'U',
                          style: AppTypography.labelLarge(c.accent)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Student',
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 17)),
                          Text(user?.email ?? '',
                              style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.accentLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(user?.accountType.label ?? 'Student',
                          style: AppTypography.mono(c.accent, size: 11)),
                    ),
                  ],
                ),
              ),

              // Appearance
              _Section(
                title: 'Appearance',
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeOption(
                        icon: LucideIcons.sun,
                        label: 'Light',
                        selected: !isDark,
                        onTap: () => context.read<ThemeCubit>().set(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ThemeOption(
                        icon: LucideIcons.moon,
                        label: 'Dark',
                        selected: isDark,
                        onTap: () => context.read<ThemeCubit>().set(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
              ),

              // Sound
              _Section(
                title: 'Sound',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _soundEnabled,
                  activeColor: c.accent,
                  onChanged: (v) => setState(() => _soundEnabled = v),
                  title: Text('Sound effects', style: AppTypography.bodyLarge(c.textPrimary)),
                  subtitle: Text('Enable click sounds and success chimes',
                      style: AppTypography.bodySmall(c.textMuted)),
                ),
              ),

              // Danger zone
              _Section(
                title: 'Danger Zone',
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<ProfileCubit>().clear();
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                    context.go(RoutePaths.login);
                  },
                  icon: Icon(LucideIcons.logOut, size: 16, color: c.danger),
                  label: Text('Log out', style: AppTypography.button(c.danger)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.danger),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
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
          Text(title, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
          const SizedBox(height: 14),
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
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? c.accentLight : c.bgRaised,
          border: Border.all(color: selected ? c.accent : c.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? c.accent : c.textMuted),
            const SizedBox(height: 6),
            Text(label,
                style: AppTypography.labelLarge(selected ? c.accent : c.textPrimary)
                    .copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
