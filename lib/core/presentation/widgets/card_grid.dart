import 'package:flutter/material.dart';

/// A responsive grid of equal-width, equal-height cards.
///
/// Cards auto-fit to [minWidth]; cards in each row stretch to the tallest
/// card's height via [IntrinsicHeight]. Use only for small item counts
/// (dashboards, stat panels) — IntrinsicHeight does two layout passes per row.
class CardGrid extends StatelessWidget {
  const CardGrid({super.key, required this.children, this.minWidth = 280, this.gap = 12.0});

  final List<Widget> children;
  final double minWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, cons) {
      final cols = (cons.maxWidth / minWidth).floor().clamp(1, children.length).toInt();
      final width = (cons.maxWidth - gap * (cols - 1)) / cols;

      final rows = <List<Widget>>[];
      for (var i = 0; i < children.length; i += cols) {
        rows.add(children.sublist(i, (i + cols).clamp(0, children.length)));
      }

      return Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < rows[i].length; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    SizedBox(
                      width: cols == 1 ? cons.maxWidth : width,
                      child: rows[i][j],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}
