part of '../dashboard_page.dart';

class _GradientIcon extends StatelessWidget {
  const _GradientIcon(this.icon, {this.secondary = false});
  final IconData icon;
  final bool secondary;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = secondary ? c.accentSecondary : c.accent;
    final dark = Color.lerp(base, Colors.black, 0.3)!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, dark],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

/// A responsive grid of equal-width cards (auto-fit, min [minWidth] wide).
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children, this.minWidth = 280});
  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final cols = (cons.maxWidth / minWidth).floor().clamp(1, children.length).toInt();
      const gap = 12.0;
      final width = (cons.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: cols == 1 ? cons.maxWidth : width, child: child),
        ],
      );
    });
  }
}

/// The full streak display from the frontend: current streak (gradient flame
/// number + milestone bar), best streak, freeze count, and next milestone —
/// each a labelled segment separated by thin dividers.
class _StreakDisplay extends StatelessWidget {
  const _StreakDisplay({
    required this.data,
    required this.practicedToday,
    required this.loading,
  });
  final DashboardData data;
  final bool practicedToday;
  final bool loading;

  static const _flame = Color(0xFFE8722A);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (loading) {
      return Container(
        width: 90,
        height: 36,
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.border),
        ),
      );
    }

    final current = data.currentStreak;
    final best = data.longestStreak;
    final freezes = data.freezesRemaining;
    final nextMilestone = (current / 5).ceil() * 5 + (current % 5 == 0 ? 5 : 0);
    final prevMilestone = nextMilestone - 5;
    final milestoneProgress =
        current > 0 ? ((current - prevMilestone) / 5).clamp(0.0, 1.0) : 0.0;
    final atRisk = !practicedToday && current > 0;

    final divider = Container(width: 1, height: 28, color: c.border);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: atRisk ? _flame.withValues(alpha: 0.5) : c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current streak
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.flame,
                      size: 14, color: current > 0 ? _flame : c.textMuted),
                  const SizedBox(width: 4),
                  if (current > 0)
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_flame, Color(0xFFFFB347)],
                      ).createShader(b),
                      child: Text('$current',
                          style: AppTypography.mono(Colors.white, size: 22)
                              .copyWith(fontWeight: FontWeight.w800, height: 1)),
                    )
                  else
                    Text('0',
                        style: AppTypography.mono(c.textMuted, size: 22)
                            .copyWith(fontWeight: FontWeight.w800, height: 1)),
                ],
              ),
              const SizedBox(height: 3),
              Text(practicedToday ? 'TODAY ✓' : 'STREAK',
                  style: AppTypography.mono(practicedToday ? c.accent : c.textMuted, size: 9)
                      .copyWith(letterSpacing: 1)),
              if (current > 0) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: 36,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: milestoneProgress,
                      minHeight: 3,
                      backgroundColor: c.border,
                      valueColor: AlwaysStoppedAnimation(c.accent),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 14),
          divider,
          const SizedBox(width: 14),
          // Best streak
          _MetricSegment(
            icon: LucideIcons.trophy,
            iconColor: c.accentSecondary,
            value: '$best',
            label: best > 0 && current >= best ? 'PERSONAL BEST!' : 'BEST',
            labelColor: best > 0 && current >= best ? c.accent : c.textMuted,
          ),
          const SizedBox(width: 14),
          divider,
          const SizedBox(width: 14),
          // Freeze
          _MetricSegment(
            icon: freezes > 0 ? LucideIcons.shield : LucideIcons.shieldOff,
            iconColor: freezes > 0 ? c.accent : c.textMuted,
            value: '$freezes',
            label: 'FREEZE',
            labelColor: c.textMuted,
          ),
          const SizedBox(width: 14),
          divider,
          const SizedBox(width: 14),
          // Next milestone
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$nextMilestone',
                  style: AppTypography.mono(c.textPrimary, size: 16)
                      .copyWith(fontWeight: FontWeight.w700, height: 1)),
              const SizedBox(height: 3),
              Text('GOAL',
                  style: AppTypography.mono(c.textMuted, size: 9).copyWith(letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small icon + number + mono label column used inside [_StreakDisplay].
class _MetricSegment extends StatelessWidget {
  const _MetricSegment({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.labelColor,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color labelColor;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(value,
                style: AppTypography.mono(c.textPrimary, size: 16)
                    .copyWith(fontWeight: FontWeight.w700, height: 1)),
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: AppTypography.mono(labelColor, size: 9).copyWith(letterSpacing: 1)),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.bgCard,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: c.textMuted),
        ),
      ),
    );
  }
}
