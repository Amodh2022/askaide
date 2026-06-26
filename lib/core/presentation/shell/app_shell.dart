import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../router/route_paths.dart';
import '../../sound/sound_cubit.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';
import '../widgets/brand_logo.dart';
import '../../../features/session/presentation/bloc/session_bloc.dart';
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

class _AuthenticatedScaffold extends StatelessWidget {
  const _AuthenticatedScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const AppSidebar(),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: child),
                    // const AiAssistantWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _MobileAuthScaffold(child: child);
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
