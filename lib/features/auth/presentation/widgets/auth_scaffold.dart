import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Shared chrome for the bare auth screens (login / signup / verify / reset).
/// A thin top bar with the wordmark (links home) + a mono section tag, then a
/// centred column constrained to 420px — mirrors the frontend's auth layout.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.tag, required this.child});

  /// The right-aligned mono tag in the top bar, e.g. "SIGN IN".
  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => context.go(RoutePaths.landing),
                  child: const _Wordmark(),
                ),
                Text(tag, style: AppTypography.sectionLabel(c.textMuted)),
              ],
            ),
          ),
          // Centred content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Compact wordmark used in the auth top bar: accent "a" tile + "askaide".
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onAccent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF14140F)
        : Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            'a',
            style: AppTypography.serifEmphasis(onAccent, size: 14)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'askaide',
          style: AppTypography.h4(c.textPrimary)
              .copyWith(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Section eyebrow: "— LABEL" in accent mono.
class AuthEyebrow extends StatelessWidget {
  const AuthEyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text('— $text', style: AppTypography.sectionLabel(context.colors.accent)),
    );
  }
}

/// The serif heading with an italic emphasis word, e.g. "Sign in.".
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.lead, required this.emphasis});

  final String lead;
  final String emphasis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: AppTypography.h1(c.textPrimary).copyWith(height: 1.0),
          children: [
            TextSpan(text: '$lead '),
            TextSpan(
              text: emphasis,
              style: AppTypography.h1(c.textPrimary)
                  .copyWith(fontStyle: FontStyle.italic, height: 1.0),
            ),
          ],
        ),
      ),
    );
  }
}
