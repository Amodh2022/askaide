import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../features/profile/domain/entities/account_type.dart';
import '../../../features/profile/domain/entities/user.dart';
import '../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../features/session/presentation/bloc/session_bloc.dart';
import '../../router/route_paths.dart';
import '../../sound/sound_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../theme/theme_cubit.dart';
import '../../utils/responsive.dart';
import '../widgets/brand_logo.dart';
import '../widgets/confirm_dialog.dart';
import 'nav_items.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/mobile_bottom_nav.dart';
import 'widgets/public_navbar.dart';
import 'widgets/whatsapp_fab.dart';

/// The single scaffold that wraps every route (a GoRouter ShellRoute child).
/// It picks the right chrome from the current location:
///  - bare routes (login/signup/reset) → no chrome
///  - public routes → top navbar + WhatsApp FAB
///  - authenticated → desktop sidebar OR mobile bottom-nav + drawer, plus the
///    floating AI assistant.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (RoutePaths.isBare(location)) {
      return Scaffold(body: child);
    }
    if (RoutePaths.isPublic(location)) {
      return _PublicScaffold(child: child);
    }
    return _AuthenticatedScaffold(child: child);
  }
}

class _PublicScaffold extends StatelessWidget {
  const _PublicScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Navbar lives in the body (not as `appBar`) so its own SafeArea reserves
    // the status-bar inset; the content scrolls beneath the fixed bar. The mobile
    // menu opens [PublicNavDrawer] (a side drawer) rather than a bottom sheet.
    return Scaffold(
      drawer: const PublicNavDrawer(),
      floatingActionButton: const WhatsAppFab(),
      body: Column(
        children: [
          const PublicNavbar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AuthenticatedScaffold extends StatefulWidget {
  const _AuthenticatedScaffold({required this.child});
  final Widget child;

  @override
  State<_AuthenticatedScaffold> createState() => _AuthenticatedScaffoldState();
}

class _AuthenticatedScaffoldState extends State<_AuthenticatedScaffold> {
  bool _sidebarOpen = true;

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              _CollapsibleSidebar(
                open: _sidebarOpen,
                onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _MobileAuthScaffold(child: widget.child);
  }
}

/// Animated sidebar that collapses to icon-only mode (~64px) on all desktop sizes.
class _CollapsibleSidebar extends StatelessWidget {
  const _CollapsibleSidebar({required this.open, required this.onToggle});
  final bool open;
  final VoidCallback onToggle;

  static const _collapsedWidth = 64.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: open ? AppSpacing.sidebarWidth : _collapsedWidth,
      child: RepaintBoundary(
        child: open
            ? AppSidebar(onCollapse: onToggle)
            : _CollapsedSidebar(onToggle: onToggle),
      ),
    );
  }
}

/// Icon-only sidebar shown when collapsed. Every item is centred, no labels.
class _CollapsedSidebar extends StatelessWidget {
  const _CollapsedSidebar({required this.onToggle});
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.select<ProfileCubit, User?>((cu) => cu.state.user);
    final role = user?.accountType ?? AccountType.student;
    final items = navItemsFor(role);
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: _CollapsibleSidebar._collapsedWidth,
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          // Brand mark only (full wordmark doesn't fit in 64px rail)
          Builder(builder: (context) {
            final c = context.colors;
            final isDarkMark =
                Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(28 * 0.28),
              ),
              alignment: Alignment.center,
              child: Text(
                'a',
                style: AppTypography.h4(
                  isDarkMark
                      ? const Color(0xFF14140F)
                      : Colors.white,
                ).copyWith(fontSize: 28 * 0.62, height: 1),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          // User avatar only
          CircleAvatar(
            radius: 16,
            backgroundColor: c.accentLight,
            child: Text(
              user?.initials ?? 'U',
              style: AppTypography.labelLarge(c.accent).copyWith(fontSize: 11),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: c.borderSubtle),
          const SizedBox(height: AppSpacing.xs),
          // Nav items
          Expanded(
            child: ListView(
              children: [
                for (final item in items) ...[
                  const SizedBox(height: 2),
                  _CollapsedNavIcon(
                    item: item,
                    active: location == item.path || location.startsWith('${item.path}/'),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: c.borderSubtle),
          const SizedBox(height: AppSpacing.xxs),
          // Theme toggle
          _CollapsedIcon(
            icon: isDark ? LucideIcons.sun : LucideIcons.moon,
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onTap: () {
              context.read<SoundCubit>().playClick();
              context.read<ThemeCubit>().toggle(Theme.of(context).brightness);
            },
          ),
          const SizedBox(height: 2),
          // Expand button
          _CollapsedIcon(
            icon: LucideIcons.panelRightOpen,
            tooltip: 'Expand sidebar',
            color: c.accent,
            onTap: onToggle,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

/// A single icon-only nav item for the collapsed sidebar.
class _CollapsedNavIcon extends StatelessWidget {
  const _CollapsedNavIcon({required this.item, required this.active});
  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: item.label,
        child: Material(
          color: active ? c.accentLight : Colors.transparent,
          borderRadius: AppRadii.modalR,
          child: InkWell(
            borderRadius: AppRadii.modalR,
            onTap: () async {
              context.read<SoundCubit>().playClick();
              final sessionBloc = context.read<SessionBloc>();
              if (sessionBloc.state.panel == SessionPanel.practice) {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'End Session?',
                  message: 'Do you want to end your current practice session?',
                  confirmLabel: 'End Session',
                  destructive: true,
                );
                if (!confirmed || !context.mounted) return;
                // End session: reset to config panel, stay on study.
                sessionBloc.add(const BackToConfigRequested());
                return;
              }
              if (context.mounted) context.go(item.path);
            },
            child: SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(item.icon,
                      size: 20, color: active ? c.accent : c.textSecondary),
                  if (active)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: c.accent, shape: BoxShape.circle),
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

/// A generic icon button for the collapsed sidebar (theme toggle, expand, etc.).
class _CollapsedIcon extends StatelessWidget {
  const _CollapsedIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.modalR,
            onTap: onTap,
            child: SizedBox(
              height: 40,
              child: Icon(icon, size: 20, color: color ?? c.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile authenticated chrome: app bar + drawer + bottom nav + AI FAB.
///
/// On iOS the glass bottom nav floats over the body (so content scrolls behind
/// it with no opaque background) and auto-hides on scroll-down / reveals on
/// scroll-up. Other platforms keep the Material bar in the normal scaffold slot.
class _MobileAuthScaffold extends StatefulWidget {
  const _MobileAuthScaffold({required this.child});
  final Widget child;

  @override
  State<_MobileAuthScaffold> createState() => _MobileAuthScaffoldState();
}

class _MobileAuthScaffoldState extends State<_MobileAuthScaffold> {
  bool _navVisible = true;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static const _bottomNavPaths = [
    RoutePaths.study,
    RoutePaths.dashboard,
    RoutePaths.progress,
    RoutePaths.quizzes,
  ];

  bool _showBottomNav(String location) {
    return _bottomNavPaths.any(
      (p) => location == p || location.startsWith('$p/'),
    );
  }

  /// Hide the floating nav while scrolling down, reveal it while scrolling up.
  bool _onScroll(ScrollNotification n) {
    if (n is UserScrollNotification) {
      if (n.direction == ScrollDirection.reverse && _navVisible) {
        setState(() => _navVisible = false);
      } else if (n.direction == ScrollDirection.forward && !_navVisible) {
        setState(() => _navVisible = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final location = GoRouterState.of(context).uri.path;
    final showNav = _showBottomNav(location);

    // Hide all navigation chrome while a practice session is active so the
    // student can focus. The BLoC is app-root-scoped so it's always readable.
    final isPracticing = context.select<SessionBloc, bool>(
      (b) => b.state.panel == SessionPanel.practice,
    );

    return Scaffold(
      appBar: isPracticing
          ? null
          : AppBar(
              backgroundColor: c.bgPrimary,
              title: const BrandLogo(size: 24),
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    context.read<SoundCubit>().playClick();
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),
      drawer: const Drawer(child: SafeArea(child: AppSidebar())),
      // iOS floats the glass bar in the body Stack instead; everyone else uses
      // the standard slot.
      bottomNavigationBar:
          (_isIOS || !showNav || isPracticing) ? null : const MobileBottomNav(),
      body: SafeArea(
        // When the AppBar is hidden we need to reserve the status-bar inset
        // ourselves so content doesn't render behind the system status bar.
        top: isPracticing,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: _isIOS
                  ? NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: widget.child,
                    )
                  : widget.child,
            ),
            if (_isIOS && showNav && !isPracticing)
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  offset: _navVisible ? Offset.zero : const Offset(0, 1),
                  child: const MobileBottomNav(),
                ),
              ),
            // AiAssistantWidget(bottomOffset: _assistantBottomOffset(context)),
          ],
        ),
      ),
    );
  }
}
