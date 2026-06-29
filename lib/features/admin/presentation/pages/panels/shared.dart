part of '../admin_dashboard_page.dart';

class _PersonRow {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
  }
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

// ─────────────────────────────────────────────────────────────────────────────
// Upload panel — pick a PDF and create a chapter via POST /chapters/create-with-pdf
// ─────────────────────────────────────────────────────────────────────────────

