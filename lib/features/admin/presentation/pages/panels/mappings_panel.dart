part of '../admin_dashboard_page.dart';

class _MappingsPanel extends StatefulWidget {
  const _MappingsPanel({super.key});
  @override
  State<_MappingsPanel> createState() => _MappingsPanelState();
}

class _MappingsPanelState extends State<_MappingsPanel> {
  final _repo = sl<AdminRepository>();

  String? _teacherId;
  String? _classId;
  String? _sectionId;
  String? _subjectId;
  final Set<String> _studentIds = {};

  List<AdminRecord> _subjects = const [];
  List<AdminRecord> _classSections = const [];
  bool _saving = false;

  String? get _schoolId => context.read<AdminCubit>().state.selectedSchoolId;

  void _onSchoolChanged(String schoolId) {
    context.read<AdminCubit>().selectSchool(schoolId);
    setState(() {
      _teacherId = null;
      _classId = null;
      _sectionId = null;
      _subjectId = null;
      _studentIds.clear();
      _subjects = const [];
      _classSections = const [];
    });
  }

  Future<void> _onClassChanged(String classId) async {
    final schoolId = _schoolId;
    setState(() {
      _classId = classId;
      _sectionId = null;
      _subjectId = null;
      _subjects = const [];
      _classSections = const [];
    });
    final subF = _repo.subjects(classId);
    final sub = await subF;
    if (!mounted) return;
    setState(() => _subjects = sub.getOrElse(() => const []));
    if (schoolId != null) {
      final sec = await _repo.sectionsByClass(schoolId, classId);
      if (!mounted) return;
      setState(() => _classSections = sec.getOrElse(() => const []));
    }
  }

  Future<void> _submit(AdminState state) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null || _teacherId == null || _classId == null ||
        _subjectId == null || _studentIds.isEmpty) { return; }
    setState(() => _saving = true);
    final r = await _repo.createTeacherStudentLink(
      schoolId: schoolId,
      teacherId: _teacherId!,
      studentIds: _studentIds.toList(),
      sectionId: _sectionId,
      classId: _classId,
      subjectId: _subjectId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.isRight() ? 'Mapping created successfully' : 'Could not create mapping')));
    if (r.isRight()) setState(() => _studentIds.clear());
  }



  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    final students = state.students;
    final allSelected = students.isNotEmpty && _studentIds.length == students.length;
    final canSubmit = _teacherId != null && _classId != null &&
        _subjectId != null && _studentIds.isNotEmpty && !_saving;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
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
            onChanged: _onSchoolChanged,
          ),
          const SizedBox(height: 14),

          // ── Teacher ─────────────────────────────────────────────────────────
          _PickerField(
            label: 'Teacher',
            hint: 'Select teacher…',
            items: state.teachers,
            selectedId: _teacherId,
            onChanged: (v) => setState(() => _teacherId = v),
          ),
          const SizedBox(height: 14),

          // ── Class + Section row ──────────────────────────────────────────────
          if (context.isMobile) ...[
            _PickerField(
              label: 'Class',
              hint: 'Select class…',
              items: state.classes,
              selectedId: _classId,
              onChanged: _onClassChanged,
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'Section (optional)',
              hint: _classId == null ? 'Pick class first' : 'Select section…',
              items: [
                const AdminRecord(id: '__none__', name: 'None'),
                ..._classSections,
              ],
              selectedId: _sectionId,
              onChanged: (v) =>
                  setState(() => _sectionId = v == '__none__' ? null : v),
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
                    selectedId: _classId,
                    onChanged: _onClassChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Section (optional)',
                    hint: _classId == null ? 'Pick class first' : 'Select section…',
                    items: [
                      const AdminRecord(id: '__none__', name: 'None'),
                      ..._classSections,
                    ],
                    selectedId: _sectionId,
                    onChanged: (v) =>
                        setState(() => _sectionId = v == '__none__' ? null : v),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),

          // ── Subject ─────────────────────────────────────────────────────────
          _PickerField(
            label: 'Subject',
            hint: _classId == null ? 'Pick class first' : 'Select subject…',
            items: _subjects,
            selectedId: _subjectId,
            onChanged: (v) => setState(() => _subjectId = v),
          ),
          const SizedBox(height: 20),

          // ── Students ────────────────────────────────────────────────────────
          Row(
            children: [
              Text('STUDENTS', style: AppTypography.mono(c.textMuted, size: 10)),
              const SizedBox(width: 8),
              if (_studentIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: AppRadii.pillR,
                  ),
                  child: Text('${_studentIds.length} selected',
                      style: AppTypography.mono(Colors.white, size: 9)),
                ),
              const Spacer(),
              if (students.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    allSelected
                        ? _studentIds.clear()
                        : _studentIds.addAll(students.map((s) => s.id));
                  }),
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
                borderRadius: AppRadii.componentR,
              ),
              child: Column(
                children: [
                  for (int i = 0; i < students.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.borderSubtle),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      value: _studentIds.contains(students[i].id),
                      activeColor: c.accent,
                      checkColor: Colors.white,
                      title: Text(students[i].name,
                          style: AppTypography.bodyMedium(c.textPrimary)),
                      subtitle: students[i].subtitle.isEmpty
                          ? null
                          : Text(students[i].subtitle,
                              style: AppTypography.bodySmall(c.textMuted)),
                      onChanged: (v) => setState(() {
                        v == true
                            ? _studentIds.add(students[i].id)
                            : _studentIds.remove(students[i].id);
                      }),
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
              onPressed: canSubmit ? () => _submit(state) : null,
              icon: _saving
                  ? const BtnSpinner()
                  : const Icon(Icons.link, size: 16),
              label: Text(_saving
                  ? 'Linking…'
                  : 'Link ${_studentIds.length} student${_studentIds.length != 1 ? 's' : ''}'),
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
