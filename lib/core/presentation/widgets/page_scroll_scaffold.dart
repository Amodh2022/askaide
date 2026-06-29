import 'package:flutter/material.dart';

/// Wraps page content in the standard authenticated-page scroll container:
/// [SingleChildScrollView] → [Center] → [ConstrainedBox] → [Column].
class PageScrollScaffold extends StatelessWidget {
  const PageScrollScaffold({
    super.key,
    required this.children,
    this.maxWidth = 920,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 24),
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    );
  }
}
