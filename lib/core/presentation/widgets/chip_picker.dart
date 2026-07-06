import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A `Wrap` of accent-styled `FilterChip`s for multi-select pickers
/// (chapters, question types, etc.).
class ChipPicker<T> extends StatelessWidget {
  const ChipPicker({
    super.key,
    required this.items,
    required this.isSelected,
    required this.onToggle,
    required this.labelOf,
  });

  final List<T> items;
  final bool Function(T item) isSelected;
  final ValueChanged<T> onToggle;
  final String Function(T item) labelOf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          FilterChip(
            label: Text(labelOf(item)),
            selected: isSelected(item),
            onSelected: (_) => onToggle(item),
            selectedColor: c.accentLight,
            checkmarkColor: c.accent,
          ),
      ],
    );
  }
}
