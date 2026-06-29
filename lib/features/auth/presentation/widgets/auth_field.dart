import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// A labeled text field matching the frontend's auth inputs: a small mono
/// UPPERCASE label, a serif input with a 1.5px border that turns accent on
/// focus, an optional trailing widget (e.g. password eye), and error text.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.trailing,
    this.errorText,
    this.trailingLabel,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final String? errorText;

  /// Optional widget shown on the right of the label row (e.g. "Forgot?").
  final Widget? trailingLabel;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasError = errorText != null && errorText!.isNotEmpty;
    final borderColor = hasError ? c.danger : c.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label,
                  style: AppTypography.sectionLabel(c.textMuted).copyWith(fontSize: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (trailingLabel != null) trailingLabel!,
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autofocus: autofocus,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          style: AppTypography.h4(c.textPrimary)
              .copyWith(fontSize: 17, fontWeight: FontWeight.w400),
          cursorColor: c.accent,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.bgCard,
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium(c.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: trailing,
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            enabledBorder: _border(borderColor),
            focusedBorder: _border(hasError ? c.danger : c.accent, width: 1.5),
            border: _border(borderColor),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(errorText!, style: AppTypography.bodySmall(c.danger).copyWith(fontSize: 12)),
          ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.5}) => OutlineInputBorder(
        borderRadius: AppRadii.cardR,
        borderSide: BorderSide(color: color, width: width),
      );
}
