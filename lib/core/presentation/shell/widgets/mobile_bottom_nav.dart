import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/profile/domain/entities/account_type.dart';
import '../../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../nav_items.dart';

/// Bottom navigation shown on mobile for all non-public routes. Items are the
/// role-filtered subset flagged `showInBottomNav`.
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

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => context.go(items[i].path),
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
