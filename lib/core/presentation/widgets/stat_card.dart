import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// A compact stat card: icon + large number + mono label, in a card-decorated box.
/// Used on dashboard, quiz list, profile, referral, and teacher panels.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.expanded = true,
  });

  final IconData icon;
  final String value;
  final String label;

  /// Icon and accent color. Defaults to [AskAideColors.accent].
  final Color? color;

  /// When true, wraps in [Expanded] so the card fills its flex slot in a Row.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final iconColor = color ?? c.accent;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.statNumber(c.textPrimary, size: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
        ],
      ),
    );
    return expanded ? Expanded(child: card) : card;
  }
}
