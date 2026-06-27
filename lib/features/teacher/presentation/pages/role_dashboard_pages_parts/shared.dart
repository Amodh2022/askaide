part of '../role_dashboard_pages.dart';

// ─── helpers ──────────────────────────────────────────────────────────────────

String _subjectEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('math')) return '📐';
  if (n.contains('physics')) return '⚛️';
  if (n.contains('chem')) return '🧪';
  if (n.contains('bio')) return '🧬';
  if (n.contains('english')) return '📚';
  if (n.contains('hindi')) return '🔤';
  if (n.contains('hist')) return '🏛️';
  if (n.contains('geo')) return '🌍';
  return '📖';
}

String _relativeTime(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.day}';
}

String _statusLabel(String raw) {
  switch (raw.toUpperCase()) {
    case 'STRONG': return 'Strong';
    case 'ON_TRACK': return 'On Track';
    case 'NEEDS_ATTENTION': return 'Needs Attention';
    case 'NEEDS_REVISION': return 'Needs Revision';
    case 'NEEDS_HELP': return 'Needs Help';
    case 'MASTERED': return 'Mastered';
    case 'PRACTICING': return 'Practicing';
    case 'LEARNING': return 'Learning';
    case 'WEAK': return 'Weak';
    case 'INACTIVE': return 'Inactive';
    case 'NOT_STARTED': return 'Not Started';
    case 'HIGH_PRIORITY': return 'High Priority';
    case 'MEDIUM_PRIORITY': return 'Medium Priority';
    case 'MONITOR': return 'Monitor';
    default: return raw;
  }
}

Color _statusColor(String raw, AskAideColors c) {
  switch (raw.toUpperCase()) {
    case 'STRONG':
    case 'MASTERED':
      return c.accent;
    case 'ON_TRACK':
    case 'PRACTICING':
    case 'LEARNING':
      return c.warning;
    case 'NEEDS_ATTENTION':
    case 'NEEDS_REVISION':
    case 'MEDIUM_PRIORITY':
    case 'MONITOR':
      return c.warning;
    case 'WEAK':
    case 'NEEDS_HELP':
    case 'HIGH_PRIORITY':
      return c.danger;
    case 'INACTIVE':
    case 'NOT_STARTED':
      return c.textMuted;
    default:
      return c.textMuted;
  }
}

// ─── shared widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _statusColor(status, c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(_statusLabel(status), style: AppTypography.mono(color, size: 9)),
    );
  }
}

/// Fill colour for a mastery [ProgressBar], matching the frontend's
/// `getBarColor` thresholds. [v] is a 0–1 fraction.
Color _masteryBarColor(double v, AskAideColors c) {
  final pct = v * 100;
  if (pct >= 70) return c.accent;
  if (pct >= 50) return c.warning;
  if (pct >= 30) return c.textMuted;
  return c.danger;
}

/// Circular mastery ring with the percentage in the centre — mirrors the
/// frontend's `MasteryGauge` (SVG ring). [value] is 0–1, or 0–100 when
/// [isPercentage] is true. Colour follows the same mastery thresholds as React.
enum _GaugeSize { sm, md, lg, xl }

class _MasteryGauge extends StatelessWidget {
  const _MasteryGauge({
    required this.value,
    this.size = _GaugeSize.md,
    this.label,
  });

  final double value;
  final _GaugeSize size;
  final String? label;

  static ({double width, double stroke, double font}) _dims(_GaugeSize s) =>
      switch (s) {
        _GaugeSize.sm => (width: 48, stroke: 4, font: 12),
        _GaugeSize.md => (width: 64, stroke: 5, font: 14),
        _GaugeSize.lg => (width: 80, stroke: 6, font: 16),
        _GaugeSize.xl => (width: 120, stroke: 8, font: 20),
      };

  static Color _color(double v, AskAideColors c) {
    if (v >= 0.7) return c.success;
    if (v >= 0.5) return c.warning;
    if (v >= 0.3) return const Color(0xFF8B5CF6); // purple (no matching token)
    return c.danger;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final normalized = value.clamp(0.0, 1.0);
    final pct = (normalized * 100).round();
    final d = _dims(size);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: d.width,
          height: d.width,
          child: CustomPaint(
            painter: _GaugePainter(
              progress: normalized,
              stroke: d.stroke,
              trackColor: c.border,
              progressColor: _color(normalized, c),
            ),
            child: Center(
              child: Text('$pct%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: d.font,
                    color: c.textPrimary,
                  )),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(label!, style: AppTypography.bodySmall(c.textSecondary), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.stroke,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final double stroke;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    // Start at top (-90°) and sweep clockwise, matching the SVG gauge.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor ||
      old.stroke != stroke;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.icon, required this.label, required this.value, this.sub, this.danger = false});
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final iconColor = danger ? c.danger : c.accent;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: context.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTypography.statNumber(iconColor, size: 22)),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.mono(c.textMuted, size: 9),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!, style: AppTypography.bodySmall(c.textMuted), maxLines: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTypography.statNumber(c.accent, size: 28)),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.mono(c.textMuted, size: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap, this.filled = false, this.danger = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = filled ? c.accent : danger ? c.danger.withValues(alpha: 0.1) : c.bgCard;
    final fg = filled ? Colors.white : danger ? c.danger : c.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: filled ? c.accent : danger ? c.danger.withValues(alpha: 0.4) : c.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.bodySmall(fg).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
// ─── Shared: dropdown pill ─────────────────────────────────────────────────────

class _DropdownPill<T> extends StatelessWidget {
  const _DropdownPill({required this.value, required this.items, required this.onChanged});
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          dropdownColor: c.bgCard,
          icon: Icon(LucideIcons.chevronDown, size: 14, color: c.textMuted),
          style: AppTypography.bodySmall(c.textPrimary),
          items: [for (final it in items) DropdownMenuItem(value: it.$1, child: Text(it.$2))],
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}
