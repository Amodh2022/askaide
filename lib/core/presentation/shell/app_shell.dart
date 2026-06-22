import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/route_paths.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';
import '../widgets/brand_logo.dart';
import 'widgets/ai_assistant_widget.dart';
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
    final c = context.colors;

    if (context.isDesktop) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              const AppSidebar(),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: child),
                    const AiAssistantWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile: app bar (logo + hamburger), sidebar as drawer, bottom nav, AI FAB.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.bgPrimary,
        title: BrandLogo(size: 24),
        elevation: 0,
      ),
      drawer: const Drawer(child: AppSidebar()),
      bottomNavigationBar: const MobileBottomNav(),
      body: Stack(
        children: [
          Positioned.fill(child: child),
          const AiAssistantWidget(),
        ],
      ),
    );
  }
}
