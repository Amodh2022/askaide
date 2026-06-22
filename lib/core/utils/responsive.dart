import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Single source of truth for the 768px mobile/desktop breakpoint.
///
/// The breakpoint is measured against the screen's *shortest side* rather than
/// its current width, so a phone stays in the mobile layout (hamburger + side
/// drawer + bottom nav) in BOTH portrait and landscape — only genuinely large
/// screens (tablets/desktop) get the sidebar layout.
extension ResponsiveX on BuildContext {
  Size get _screen => MediaQuery.sizeOf(this);
  double get screenWidth => _screen.width;
  bool get isMobile => _screen.shortestSide < AppSpacing.mobileBreakpoint;
  bool get isDesktop => !isMobile;
}
