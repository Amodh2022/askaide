import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../features/profile/domain/entities/account_type.dart';
import '../../router/route_paths.dart';

/// Logical groupings shown in the desktop sidebar.
enum NavGroup { learn, manage, account }

extension NavGroupLabel on NavGroup {
  String get label => switch (this) {
        NavGroup.learn => 'LEARN',
        NavGroup.manage => 'MANAGE',
        NavGroup.account => 'ACCOUNT',
      };
}

/// A single navigation destination, with the roles allowed to see it.
class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.group,
    required this.roles,
    this.showInBottomNav = false,
  });

  final String label;
  final IconData icon;
  final String path;
  final NavGroup group;
  final Set<AccountType> roles;
  final bool showInBottomNav;

  bool visibleTo(AccountType role) => roles.contains(role);
}

const _all = {
  AccountType.student,
  AccountType.parent,
  AccountType.teacher,
  AccountType.superAdmin,
};

/// The full nav catalogue. `allNavItems` is filtered by the current role both
/// for the sidebar and the mobile bottom nav.
const List<NavItem> allNavItems = [
  // LEARN
  NavItem(
    label: 'Study',
    icon: LucideIcons.bookOpen,
    path: RoutePaths.study,
    group: NavGroup.learn,
    roles: _all,
    showInBottomNav: true,
  ),
  NavItem(
    label: 'Dashboard',
    icon: LucideIcons.layoutDashboard,
    path: RoutePaths.dashboard,
    group: NavGroup.learn,
    roles: _all,
    showInBottomNav: true,
  ),
  NavItem(
    label: 'Progress',
    icon: LucideIcons.trendingUp,
    path: RoutePaths.progress,
    group: NavGroup.learn,
    roles: _all,
    showInBottomNav: true,
  ),
  NavItem(
    label: 'Quizzes',
    icon: LucideIcons.listChecks,
    path: RoutePaths.quizzes,
    group: NavGroup.learn,
    roles: {AccountType.student, AccountType.superAdmin},
    showInBottomNav: true,
  ),
  // MANAGE
  NavItem(
    label: 'Papers',
    icon: LucideIcons.fileText,
    path: RoutePaths.questionPaper,
    group: NavGroup.manage,
    roles: {AccountType.teacher, AccountType.superAdmin},
  ),
  NavItem(
    label: 'Teacher',
    icon: LucideIcons.users,
    path: RoutePaths.teacher,
    group: NavGroup.manage,
    roles: {AccountType.teacher, AccountType.parent, AccountType.superAdmin},
  ),
  NavItem(
    label: 'Parent',
    icon: LucideIcons.heartHandshake,
    path: RoutePaths.parent,
    group: NavGroup.manage,
    roles: {AccountType.parent, AccountType.superAdmin},
  ),
  NavItem(
    label: 'Admin',
    icon: LucideIcons.shieldCheck,
    path: RoutePaths.admin,
    group: NavGroup.manage,
    roles: {AccountType.superAdmin},
  ),
  // ACCOUNT
  NavItem(
    label: 'Profile',
    icon: LucideIcons.user,
    path: RoutePaths.profile,
    group: NavGroup.account,
    roles: _all,
  ),
  NavItem(
    label: 'Refer & Earn',
    icon: LucideIcons.gift,
    path: RoutePaths.referral,
    group: NavGroup.account,
    roles: _all,
  ),
  NavItem(
    label: 'Settings',
    icon: LucideIcons.settings,
    path: RoutePaths.settings,
    group: NavGroup.account,
    roles: _all,
  ),
];

List<NavItem> navItemsFor(AccountType role) =>
    allNavItems.where((i) => i.visibleTo(role)).toList();

List<NavItem> bottomNavItemsFor(AccountType role) =>
    allNavItems.where((i) => i.showInBottomNav && i.visibleTo(role)).toList();
