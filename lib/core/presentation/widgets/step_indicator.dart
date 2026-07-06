import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Card-wrapped horizontal step tracker for multi-step wizards.
///
/// Pass [onTap] to allow jumping between steps (wraps each step in an
/// `InkWell`); omit it for a read-only indicator.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current, required this.steps, this.onTap});

  final int current;
  final List<String> steps;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: context.cardDecoration(),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
                child: _step(c, i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _step(AskAideColors c, int i) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: current == i + 1 ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            (i + 1) < current ? LucideIcons.circleCheck : LucideIcons.circle,
            size: 16,
            color: current == i + 1
                ? Colors.white
                : ((i + 1) < current ? c.success : c.textMuted),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              steps[i],
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(current == i + 1 ? Colors.white : c.textMuted),
            ),
          ),
        ],
      ),
    );
    final tap = onTap;
    if (tap == null) return content;
    return InkWell(
      onTap: () => tap(i + 1),
      borderRadius: BorderRadius.circular(4),
      child: content,
    );
  }
}
