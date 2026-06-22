import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../router/route_paths.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/theme_cubit.dart';
import '../../../utils/responsive.dart';
import '../../widgets/brand_logo.dart';

/// Top navbar for public pages: brand · center links · theme toggle · sign-in ·
/// dark "Try a session" pill. On mobile the center links collapse into a menu.
class PublicNavbar extends StatelessWidget implements PreferredSizeWidget {
  const PublicNavbar({super.key});

  static const _links = [
    ('Try Free', RoutePaths.tryNow),
    ('Free Papers', RoutePaths.freePaperGenerator),
    ('For Schools', RoutePaths.forSchools),
    ('Blog', RoutePaths.blog),
  ];

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: c.bgPrimary.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.go(RoutePaths.landing),
                  child: BrandLogo(size: 26),
                ),
                const Spacer(),
                if (context.isDesktop) ...[
                  for (final (label, path) in _links)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: TextButton(
                        onPressed: () => context.go(path),
                        child: Text(label,
                            style: AppTypography.bodyMedium(c.textSecondary)),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                IconButton(
                  tooltip: isDark ? 'Light mode' : 'Dark mode',
                  icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon,
                      size: 18, color: c.textSecondary),
                  onPressed: () => context
                      .read<ThemeCubit>()
                      .toggle(Theme.of(context).brightness),
                ),
                if (context.isDesktop) ...[
                  TextButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: Text('Sign in',
                        style: AppTypography.bodyMedium(c.textPrimary)),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _DarkPill(
                    label: 'Try a session →',
                    onTap: () => context.go(RoutePaths.tryNow),
                  ),
                ],
                // Mobile: actions collapse into a side drawer to avoid a cramped bar.
                if (context.isMobile)
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(LucideIcons.menu, color: c.textPrimary),
                      tooltip: 'Menu',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// The slide-in side drawer for public pages (mobile). Holds the same nav links,
/// sign-in, and "Try a session" CTA that the desktop navbar shows inline.
class PublicNavDrawer extends StatelessWidget {
  const PublicNavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: c.bgPrimary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.md),
              child: Row(
                children: [
                  const BrandLogo(size: 26),
                  const Spacer(),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: c.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.borderSubtle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final (label, path) in PublicNavbar._links)
                    ListTile(
                      title: Text(label, style: AppTypography.bodyLarge(c.textPrimary)),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(path);
                      },
                    ),
                  Divider(height: 1, color: c.borderSubtle),
                  ListTile(
                    leading: Icon(isDark ? LucideIcons.sun : LucideIcons.moon,
                        size: 18, color: c.textSecondary),
                    title: Text(isDark ? 'Light mode' : 'Dark mode',
                        style: AppTypography.bodyLarge(c.textPrimary)),
                    onTap: () =>
                        context.read<ThemeCubit>().toggle(Theme.of(context).brightness),
                  ),
                  ListTile(
                    title: Text('Sign in', style: AppTypography.bodyLarge(c.textPrimary)),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(RoutePaths.login);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _DarkPill(
                label: 'Try a session →',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(RoutePaths.tryNow);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onAccent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF14140F)
        : Colors.white;
    return Material(
      color: c.textPrimary,
      borderRadius: AppRadii.pillR,
      child: InkWell(
        borderRadius: AppRadii.pillR,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 10),
          child: Text(label, style: AppTypography.button(onAccent)),
        ),
      ),
    );
  }
}
