import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// The wordmark: rounded-square "a" mark + "askaide" (serif) + tiny "AI" (mono).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          alignment: Alignment.center,
          child: Text(
            'a',
            style: AppTypography.h4(
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF14140F)
                  : Colors.white,
            ).copyWith(fontSize: size * 0.62, height: 1),
          ),
        ),
        SizedBox(width: size * 0.32),
        Text('askaide',
            style: AppTypography.h4(c.textPrimary)
                .copyWith(fontSize: size * 0.72)),
        SizedBox(width: size * 0.14),
        Padding(
          padding: EdgeInsets.only(top: size * 0.12),
          child: Text('AI', style: AppTypography.sectionLabel(c.accent)),
        ),
      ],
    );
  }
}
