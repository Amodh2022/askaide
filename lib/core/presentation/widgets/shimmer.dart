import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A self-contained shimmer effect: sweeps a soft highlight band across its
/// child to signal "content loading". Hand-rolled (no package) and themed from
/// [AskAideColors] so it tracks light/dark automatically.
///
/// Wrap skeleton placeholders ([SkeletonBox] etc.) in a single [Shimmer] — the
/// gradient animates over everything painted inside, so one wrapper drives a
/// whole placeholder layout.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Base = the skeleton fill; highlight = the brighter band that sweeps over.
    final base = c.bgRaised;
    final highlight = Color.alphaBlend(
      c.textMuted.withValues(alpha: 0.10),
      c.bgCard,
    );
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * 2;
            final slide = -bounds.width + dx * _controller.value;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(slide),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Translates the shimmer gradient horizontally by [dx] logical pixels.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);
  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

// ── Primitives ──────────────────────────────────────────────────────────────

/// A solid rounded placeholder block. Its colour is irrelevant — the enclosing
/// [Shimmer]'s `srcATop` shader repaints it — but it gives the band a shape.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.bgRaised,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A card-shaped skeleton: a couple of text lines plus optional leading block.
/// Reused by list/grid loading placeholders.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 88, this.lines = 2});

  final double height;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SkeletonBox(width: 140, height: 14),
          for (var i = 1; i < lines; i++) ...[
            const SizedBox(height: 10),
            SkeletonBox(width: i.isOdd ? 220 : 180, height: 12),
          ],
        ],
      ),
    );
  }
}

/// Drop-in replacement for a centred `CircularProgressIndicator` page/section
/// loader: a vertical stack of shimmering cards. Use where content is a list or
/// generic body that's still loading.
class SkeletonListLoader extends StatelessWidget {
  const SkeletonListLoader({
    super.key,
    this.itemCount = 5,
    this.cardHeight = 88,
    this.lines = 2,
    this.padding = const EdgeInsets.all(16),
  });

  final int itemCount;
  final double cardHeight;
  final int lines;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: padding,
        // Sized to its children so it can be embedded inside a Column /
        // SingleChildScrollView without an unbounded-height error.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => SkeletonCard(height: cardHeight, lines: lines),
      ),
    );
  }
}

// ── Structured skeletons for boxes across the app ─────────────────────────

/// A circle skeleton placeholder (for avatars / badge spots).
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.bgRaised,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Matches a [_ShellCard]-style card: icon row header + optional subtitle + content area.
class SkeletonShellCard extends StatelessWidget {
  const SkeletonShellCard({
    super.key,
    this.showIcon = true,
    this.showSubtitle = false,
    this.child,
    this.height,
  });

  final bool showIcon;
  final bool showSubtitle;
  final Widget? child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showIcon) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.bgRaised,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 120, height: 14),
                    if (showSubtitle) ...[
                      const SizedBox(height: 4),
                      const SkeletonBox(width: 80, height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Matches the dashboard/profile stat cards: a medium value + mono label.
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key, this.aspectRatio});

  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AspectRatio(
      aspectRatio: aspectRatio ?? 1.05,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.bgCard,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SkeletonBox(width: 60, height: 24),
            SizedBox(height: 6),
            SkeletonBox(width: 80, height: 10),
          ],
        ),
      ),
    );
  }
}

/// Matches [_ActionCard]: a row with icon + text + trailing icon tile.
class SkeletonActionCard extends StatelessWidget {
  const SkeletonActionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 14),
                SizedBox(height: 4),
                SkeletonBox(width: 140, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches the admin _chartBox: a bordered container with title bar + chart area.
class SkeletonChartBox extends StatelessWidget {
  const SkeletonChartBox({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 160, height: 14),
          const SizedBox(height: 12),
          Container(
            height: height - 60,
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches the admin _Stat card inside _cardGrid.
class SkeletonAdminMetricCard extends StatelessWidget {
  const SkeletonAdminMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 60, height: 10),
          SizedBox(height: 8),
          SkeletonBox(width: 80, height: 20),
          SizedBox(height: 4),
          SkeletonBox(width: 100, height: 10),
        ],
      ),
    );
  }
}

/// Matches the profile header card: avatar circle + text lines.
class SkeletonProfileHeader extends StatelessWidget {
  const SkeletonProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SkeletonCircle(size: 88),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 180, height: 18),
                const SizedBox(height: 8),
                const SkeletonBox(width: 140, height: 12),
                const SizedBox(height: 6),
                const SkeletonBox(width: 120, height: 12),
                const SizedBox(height: 10),
                Container(
                  width: 70,
                  height: 24,
                  decoration: BoxDecoration(
                    color: context.colors.bgRaised,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
