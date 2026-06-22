import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Themed stand-in for screens implemented in later build steps. Renders the
/// "Quiet Scholar" type scale so the running shell demonstrates the design
/// system on every route.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.label,
    required this.title,
    this.emphasis,
    this.description,
  });

  final String label;
  final String title;
  final String? emphasis;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('— ${label.toUpperCase()}',
                  style: AppTypography.sectionLabel(c.textMuted)),
              const SizedBox(height: AppSpacing.sm),
              RichText(
                text: TextSpan(
                  style: AppTypography.h1(c.textPrimary),
                  children: [
                    TextSpan(text: '$title '),
                    if (emphasis != null)
                      TextSpan(
                        text: emphasis,
                        style: AppTypography.serifEmphasis(c.accent, size: 44),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                description ??
                    'This screen is scaffolded and will be built in a later step.',
                style: AppTypography.bodyLarge(c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: context.cardDecoration(),
                child: Text(
                  'Theme + routing are live — light/dark and the sidebar/'
                  'navbar adapt automatically.',
                  style: AppTypography.bodyMedium(c.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
