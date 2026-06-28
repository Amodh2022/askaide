import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/profile/domain/entities/account_type.dart';
import '../../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../sound/sound_cubit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/theme_cubit.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/confirm_dialog.dart';
import '../nav_items.dart';

/// Fixed 240px left rail shown on desktop for authenticated routes. Groups are
/// role-filtered; the active item switches to the serif font with an
/// accent-light pill and a small accent dot.
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.watch<ProfileCubit>().state.user;
    final role = user?.accountType ?? AccountType.student;
    final items = navItemsFor(role);
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top: logo + user.
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
            child: BrandLogo(size: 26),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _UserCard(
              name: user?.name ?? 'Learner',
              role: role,
              image: user?.image,
              initials: user?.initials ?? 'U',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: c.borderSubtle),

          // Grouped nav.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                for (final group in NavGroup.values)
                  ..._buildGroup(context, group, items, location),
              ],
            ),
          ),

          Divider(height: 1, color: c.borderSubtle),
          // Bottom: theme toggle + sign out.
          _ThemeToggleTile(),
          _SignOutTile(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    NavGroup group,
    List<NavItem> items,
    String location,
  ) {
    final groupItems = items.where((i) => i.group == group).toList();
    if (groupItems.isEmpty) return const [];
    final c = context.colors;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
        child: Text(group.label, style: AppTypography.sectionLabel(c.textMuted)),
      ),
      for (final item in groupItems)
        _NavTile(
          item: item,
          active: location == item.path || location.startsWith('${item.path}/'),
        ),
    ];
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active});
  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: 2),
      child: Material(
        color: active ? c.accentLight : Colors.transparent,
        borderRadius: AppRadii.modalR,
        child: InkWell(
          borderRadius: AppRadii.modalR,
          onTap: () {
            context.read<SoundCubit>().playClick();
            // On mobile the sidebar lives in a Drawer; close it after picking a
            // destination. No-op on desktop where the rail is persistent.
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold?.isDrawerOpen ?? false) scaffold!.closeDrawer();
            context.go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 18, color: active ? c.accent : c.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.label,
                    style: active
                        ? AppTypography.h4(c.accent).copyWith(fontSize: 15)
                        : AppTypography.bodyMedium(c.textSecondary),
                  ),
                ),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.name,
    required this.role,
    required this.initials,
    this.image,
  });
  final String name;
  final AccountType role;
  final String initials;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: c.accentLight,
          backgroundImage: (image != null && image!.isNotEmpty)
              ? NetworkImage(image!)
              : null,
          onBackgroundImageError: (image != null && image!.isNotEmpty)
              ? (_, __) {}
              : null,
          child: (image == null || image!.isEmpty)
              ? Text(initials,
                  style: AppTypography.labelLarge(c.accent).copyWith(fontSize: 13))
              : Text(initials,
                  style: AppTypography.labelLarge(c.accent).copyWith(fontSize: 13)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge(c.textPrimary)
                      .copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: AppRadii.pillR,
                ),
                child: Text(role.label.toUpperCase(),
                    style: AppTypography.mono(c.accent, size: 9)
                        .copyWith(letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(isDark ? LucideIcons.sun : LucideIcons.moon,
            size: 18, color: c.textSecondary),
        title: Text(isDark ? 'Light mode' : 'Dark mode',
            style: AppTypography.bodyMedium(c.textSecondary)),
        onTap: () {
          context.read<SoundCubit>().playClick();
          context.read<ThemeCubit>().toggle(Theme.of(context).brightness);
        },
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(LucideIcons.logOut, size: 18, color: c.danger),
        title: Text('Sign out', style: AppTypography.bodyMedium(c.danger)),
        onTap: () async {
          context.read<SoundCubit>().playClick();
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
        },
      ),
    );
  }
}
