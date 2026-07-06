part of '../admin_dashboard_page.dart';

/// Pins the tab chip strip to the top of the scroll view.
class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  _PinnedTabBar({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);
  @override
  bool shouldRebuild(covariant _PinnedTabBar old) =>
      old.height != height || old.child != child;
}

/// A small class → subject selector header shared by the curriculum tabs.
class _ClassSubjectSelector extends StatelessWidget {
  const _ClassSubjectSelector({
    required this.classes,
    required this.classId,
    required this.subjects,
    required this.subjectId,
    required this.onClass,
    required this.onSubject,
  });
  final List<AdminRecord> classes;
  final String? classId;
  final List<AdminRecord> subjects;
  final String? subjectId;
  final ValueChanged<String> onClass;
  final ValueChanged<String> onSubject;

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PickerField(
                  label: 'Class',
                  hint: 'Select class…',
                  items: classes,
                  selectedId: classId,
                  onChanged: onClass,
                ),
                const SizedBox(height: 12),
                _PickerField(
                  label: 'Subject',
                  hint: 'Select subject…',
                  items: subjects,
                  selectedId: subjectId,
                  onChanged: onSubject,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Class',
                    hint: 'Select class…',
                    items: classes,
                    selectedId: classId,
                    onChanged: onClass,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Subject',
                    hint: 'Select subject…',
                    items: subjects,
                    selectedId: subjectId,
                    onChanged: onSubject,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Labeled `TextFormField` shared across the admin create/edit forms.
/// Composes [RequiredValidator]/[EmailFormatValidator]/[MinLengthValidator]
/// via [validateField] instead of each panel hand-rolling its own checks.
class AdminFormField extends StatelessWidget {
  const AdminFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.requiredField = false,
    this.requiredMessage = 'Required',
    this.email = false,
    this.emailMessage = 'Invalid',
    this.minLen,
    this.minLenMessage,
    this.trailing,
    this.dense = true,
    this.applyBodyStyle = true,
    this.labelColor,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool requiredField;
  final String requiredMessage;
  final bool email;
  final String emailMessage;
  final int? minLen;
  final String? minLenMessage;
  final Widget? trailing;

  /// Preserves students/teachers' `isDense: true` vs schools' unset (false).
  final bool dense;

  /// Preserves students/teachers' explicit `bodySmall` field style vs
  /// schools' theme-default style.
  final bool applyBodyStyle;

  /// Preserves schools' `textSecondary` label vs students/teachers' `textMuted`.
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = TextFormField(
      controller: controller,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      style: applyBodyStyle ? AppTypography.bodySmall(c.textPrimary) : null,
      decoration: InputDecoration(hintText: hint, isDense: dense),
      validator: (v) {
        final t = (v ?? '').trim();
        return validateField(t, [
          if (requiredField) RequiredValidator(requiredMessage),
          if (t.isNotEmpty && email) EmailFormatValidator(emailMessage),
          if (t.isNotEmpty && minLen != null) MinLengthValidator(minLen!, message: minLenMessage),
        ]);
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(labelColor ?? c.textMuted, size: 10)),
        const SizedBox(height: 6),
        trailing == null
            ? field
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: field),
                trailing!,
              ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload panel — pick a PDF and create a chapter via POST /chapters/create-with-pdf
// ─────────────────────────────────────────────────────────────────────────────

