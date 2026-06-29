import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Standard content-page header: a mono "— EYEBROW" tag above a serif heading
/// with an optional italic emphasis word. Used by the dashboard/quiz/role pages
/// to match the frontend's editorial section headers.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.emphasis,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? emphasis;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = '— ${eyebrow.toUpperCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.sectionLabel(c.accent)),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: AppTypography.h1(c.textPrimary).copyWith(fontSize: 36),
            children: [
              TextSpan(text: emphasis == null ? title : '$title '),
              if (emphasis != null)
                TextSpan(
                    text: emphasis,
                    style: AppTypography.serifEmphasis(c.textPrimary, size: 36)),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: AppTypography.bodyLarge(c.textMuted)),
        ],
      ],
    );
  }
}

/// A centered empty-state block: icon, title, and a one-line hint.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.hint});

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: c.textMuted),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(hint, textAlign: TextAlign.center, style: AppTypography.bodyMedium(c.textMuted)),
          ],
        ),
      ),
    );
  }
}
