import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

import '../../../../features/profile/domain/entities/account_type.dart';
import '../../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../sound/sound_cubit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../nav_items.dart';

/// Bottom navigation shown on mobile for all non-public routes. Items are the
/// role-filtered subset flagged `showInBottomNav`.
///
/// On iOS this renders the native liquid-glass tab bar
/// ([NativeGlassNavBar]); every other platform (Android, web, older iOS)
/// keeps the Material [BottomNavigationBar] design.
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final role =
        context.watch<ProfileCubit>().state.role ?? AccountType.student;
    final items = bottomNavItemsFor(role);
    final location = GoRouterState.of(context).uri.path;

    var index = items.indexWhere(
      (i) => location == i.path || location.startsWith('${i.path}/'),
    );
    if (index < 0) index = 0;

    void go(int i) {
      context.read<SoundCubit>().playClick();
      context.go(items[i].path);
    }

    final material = _MaterialBottomNav(
      items: items,
      index: index,
      onTap: go,
    );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return NativeGlassNavBar(
        currentIndex: index,
        onTap: go,
        tintColor: c.accent,
        fallback: material,
        tabs: [
          for (final item in items)
            NativeGlassNavBarItem(
              label: item.label,
              symbol: item.sfSymbol ?? 'circle',
            ),
        ],
      );
    }

    return material;
  }
}

/// The Material bottom navigation bar used on Android (and as the iOS
/// fallback when the native glass bar is unavailable).
class _MaterialBottomNav extends StatelessWidget {
  const _MaterialBottomNav({
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: c.accent,
          unselectedItemColor: c.textMuted,
          selectedLabelStyle: AppTypography.mono(c.accent, size: 10),
          unselectedLabelStyle: AppTypography.mono(c.textMuted, size: 10),
          items: [
            for (final item in items)
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(item.icon, size: 20),
                ),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }
}
