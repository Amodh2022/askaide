import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Shows a themed confirmation dialog and resolves to `true` when the user
/// confirms, `false` otherwise (cancel / dismiss).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final c = context.colors;
  final confirmColor = destructive ? c.danger : c.accent;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.bgCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.modalR),
      title: Text(title, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
      content: Text(message, style: AppTypography.bodyMedium(c.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel, style: AppTypography.button(c.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel, style: AppTypography.button(confirmColor)),
        ),
      ],
    ),
  );
  return result ?? false;
}
