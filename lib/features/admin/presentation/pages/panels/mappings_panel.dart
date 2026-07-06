part of '../admin_dashboard_page.dart';

class _MappingsPanel extends StatelessWidget {
  const _MappingsPanel();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MappingsPanelCubit>(
      create: (_) => sl<MappingsPanelCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  void _onSchoolChanged(BuildContext context, String schoolId) {
    context.read<AdminCubit>().selectSchool(schoolId);
    context.read<MappingsPanelCubit>().resetForSchoolChange();
  }

  Future<void> _submit(BuildContext context, AdminState state) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null) return;
    final panelCubit = context.read<MappingsPanelCubit>();
    final ok = await panelCubit.submit(schoolId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Mapping created successfully' : 'Could not create mapping')));
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    final panelState = context.watch<MappingsPanelCubit>().state;
    final panelCubit = context.read<MappingsPanelCubit>();
    final students = state.students;
    final allSelected = students.isNotEmpty && panelState.studentIds.length == students.length;
    final canSubmit = panelState.teacherId != null && panelState.classId != null &&
        panelState.subjectId != null && panelState.studentIds.isNotEmpty && !panelState.saving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── School ──────────────────────────────────────────────────────────
          _PickerField(
            label: 'School',
            hint: 'Select school…',
            items: state.schools
                .map((s) => AdminRecord(id: s.id, name: s.name))
                .toList(),
            selectedId: state.selectedSchoolId,
            onChanged: (v) => _onSchoolChanged(context, v),
          ),
          const SizedBox(height: 14),

          // ── Teacher ─────────────────────────────────────────────────────────
          _PickerField(
            label: 'Teacher',
            hint: 'Select teacher…',
            items: state.teachers,
            selectedId: panelState.teacherId,
            onChanged: panelCubit.setTeacher,
          ),
          const SizedBox(height: 14),

          // ── Class + Section row ──────────────────────────────────────────────
          if (context.isMobile) ...[
            _PickerField(
              label: 'Class',
              hint: 'Select class…',
              items: state.classes,
              selectedId: panelState.classId,
              onChanged: (classId) =>
                  panelCubit.selectClass(classId, state.selectedSchoolId),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'Section (optional)',
              hint: panelState.classId == null ? 'Pick class first' : 'Select section…',
              items: [
                const AdminRecord(id: '__none__', name: 'None'),
                ...panelState.classSections,
              ],
              selectedId: panelState.sectionId,
              onChanged: (v) => panelCubit.setSection(v == '__none__' ? null : v),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Class',
                    hint: 'Select class…',
                    items: state.classes,
                    selectedId: panelState.classId,
                    onChanged: (classId) =>
                        panelCubit.selectClass(classId, state.selectedSchoolId),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Section (optional)',
                    hint: panelState.classId == null ? 'Pick class first' : 'Select section…',
                    items: [
                      const AdminRecord(id: '__none__', name: 'None'),
                      ...panelState.classSections,
                    ],
                    selectedId: panelState.sectionId,
                    onChanged: (v) => panelCubit.setSection(v == '__none__' ? null : v),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),

          // ── Subject ─────────────────────────────────────────────────────────
          _PickerField(
            label: 'Subject',
            hint: panelState.classId == null ? 'Pick class first' : 'Select subject…',
            items: panelState.subjects,
            selectedId: panelState.subjectId,
            onChanged: panelCubit.setSubject,
          ),
          const SizedBox(height: 20),

          // ── Students ────────────────────────────────────────────────────────
          Row(
            children: [
              Text('STUDENTS', style: AppTypography.mono(c.textMuted, size: 10)),
              const SizedBox(width: 8),
              if (panelState.studentIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('${panelState.studentIds.length} selected',
                      style: AppTypography.mono(Colors.white, size: 9)),
                ),
              const Spacer(),
              if (students.isNotEmpty)
                GestureDetector(
                  onTap: () => panelCubit.toggleSelectAll(students.map((s) => s.id).toList()),
                  child: Text(
                    allSelected ? 'Deselect all' : 'Select all',
                    style: AppTypography.bodySmall(c.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No students in this school.',
                  style: AppTypography.bodySmall(c.textMuted)),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < students.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.borderSubtle),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      value: panelState.studentIds.contains(students[i].id),
                      activeColor: c.accent,
                      checkColor: Colors.white,
                      title: Text(students[i].name,
                          style: AppTypography.bodyMedium(c.textPrimary)),
                      subtitle: students[i].subtitle.isEmpty
                          ? null
                          : Text(students[i].subtitle,
                              style: AppTypography.bodySmall(c.textMuted)),
                      onChanged: (_) => panelCubit.toggleStudent(students[i].id),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),

          // ── Submit ──────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canSubmit ? () => _submit(context, state) : null,
              icon: panelState.saving
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.link, size: 16),
              label: Text(panelState.saving
                  ? 'Linking…'
                  : 'Link ${panelState.studentIds.length} student${panelState.studentIds.length != 1 ? 's' : ''}'),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
