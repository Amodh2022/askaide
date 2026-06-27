part of '../admin_dashboard_page.dart';

class _SectionsPanel extends StatefulWidget {
  const _SectionsPanel();
  @override
  State<_SectionsPanel> createState() => _SectionsPanelState();
}

class _SectionsPanelState extends State<_SectionsPanel> {
  final _repo = sl<AdminRepository>();
  String? _classId;
  List<AdminSection> _sections = const [];
  bool _loading = false;

  String? get _schoolId => context.read<AdminCubit>().state.selectedSchoolId;

  Future<void> _load() async {
    final schoolId = _schoolId;
    if (schoolId == null || _classId == null) return;
    setState(() => _loading = true);
    final r = await _repo.sectionsDetailed(schoolId, _classId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sections = r.getOrElse(() => const []);
    });
  }

  void _selectClass(String classId) {
    setState(() {
      _classId = classId;
      _sections = const [];
    });
    _load();
  }

  void _after(bool ok, String okMsg, String failMsg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? okMsg : failMsg)));
    if (ok) _load();
  }

  Future<void> _addSingle() async {
    final c = context.colors;
    final nameCtl = TextEditingController();
    final maxCtl = TextEditingController(text: '40');
    var saving = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) => AlertDialog(
          backgroundColor: c.bgCard,
          title: Text('Add section', style: AppTypography.h4(c.textPrimary)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Section name (e.g. A)')),
              const SizedBox(height: 10),
              TextField(
                  controller: maxCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max strength')),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final schoolId = _schoolId;
                      final classId = _classId;
                      if (schoolId == null || classId == null) return;
                      setLocal(() => saving = true);
                      final r = await _repo.createSection(nameCtl.text.trim(), schoolId,
                          classId: classId, maxStrength: int.tryParse(maxCtl.text.trim()));
                      if (dctx.mounted) Navigator.pop(dctx);
                      if (mounted) _after(r.isRight(), 'Section created', 'Could not create section');
                    },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
    Future.microtask(() {
      nameCtl.dispose();
      maxCtl.dispose();
    });
  }

  Future<void> _addBulk() async {
    final c = context.colors;
    final ctl = TextEditingController(text: 'A, B, C, D');
    var saving = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) => AlertDialog(
          backgroundColor: c.bgCard,
          title: Text('Bulk add sections', style: AppTypography.h4(c.textPrimary)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: ctl,
                  decoration: const InputDecoration(labelText: 'Section names (comma-separated)')),
              const SizedBox(height: 8),
              Text('Existing sections will be skipped.',
                  style: AppTypography.bodySmall(c.textMuted)),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      final schoolId = _schoolId;
                      final classId = _classId;
                      if (schoolId == null || classId == null) return;
                      final names = ctl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      if (names.isEmpty) return;
                      setLocal(() => saving = true);
                      final r = await _repo.createSectionsBulk(schoolId, classId, names);
                      if (dctx.mounted) Navigator.pop(dctx);
                      if (mounted) _after(r.isRight(), 'Created ${names.length} sections', 'Could not create sections');
                    },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
    Future.microtask(ctl.dispose);
  }

  Future<void> _edit(AdminSection s) async {
    final c = context.colors;
    final nameCtl = TextEditingController(text: s.name);
    final maxCtl = TextEditingController(text: '${s.maxStrength}');
    var active = s.isActive;
    var saving = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) => AlertDialog(
          backgroundColor: c.bgCard,
          title: Text('Edit section', style: AppTypography.h4(c.textPrimary)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Section name')),
              const SizedBox(height: 10),
              TextField(
                  controller: maxCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max strength')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: c.accent,
                title: Text('Active', style: AppTypography.bodyMedium(c.textPrimary)),
                value: active,
                onChanged: saving ? null : (v) => setLocal(() => active = v),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      final r = await _repo.updateSection(s.id, {
                        'name': nameCtl.text.trim(),
                        'maxStrength': int.tryParse(maxCtl.text.trim()) ?? s.maxStrength,
                        'isActive': active,
                      });
                      if (dctx.mounted) Navigator.pop(dctx);
                      if (mounted) _after(r.isRight(), 'Section updated', 'Could not update section');
                    },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    Future.microtask(() {
      nameCtl.dispose();
      maxCtl.dispose();
    });
  }

  Future<void> _delete(AdminSection s) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete Section',
        message: 'Are you sure you want to delete this section?',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok) return;
    final r = await _repo.deleteSection(s.id);
    _after(r.isRight(), 'Section deleted', 'Could not delete section');
  }


  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: _PickerField(
            label: 'School',
            hint: 'Select school…',
            items: state.schools
                .map((s) => AdminRecord(id: s.id, name: s.name))
                .toList(),
            selectedId: state.selectedSchoolId,
            onChanged: (v) {
              context.read<AdminCubit>().selectSchool(v);
              setState(() {
                _classId = null;
                _sections = const [];
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: _PickerField(
            label: 'Class',
            hint: 'Select class…',
            items: state.classes,
            selectedId: _classId,
            onChanged: _selectClass,
          ),
        ),
        if (_classId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _addBulk,
                  icon: const Icon(Icons.playlist_add, size: 16),
                  label: const Text('Bulk add'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addSingle,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add section'),
                  style: FilledButton.styleFrom(
                      backgroundColor: c.accent, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        if (_sections.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _stat(c, '${_sections.length}', 'Sections', Icons.layers_outlined),
                _stat(c, '${_sections.fold(0, (s, e) => s + e.currentStrength)}',
                    'Enrolled', Icons.people_outline),
                _stat(c, '${_sections.fold(0, (s, e) => s + e.maxStrength)}',
                    'Capacity', Icons.event_seat_outlined),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 8),
        Divider(height: 1, color: c.border),
        Expanded(
          child: _classId == null
              ? const EmptyState(
                  icon: Icons.class_outlined,
                  title: 'Pick a class',
                  hint: 'Select a class to view its sections.',
                )
              : _loading
                  ? const SkeletonListLoader()
                  : _sections.isEmpty
                      ? const EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'No sections',
                          hint: 'Create one with the buttons above.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _sections.length,
                          itemBuilder: (_, i) => _sectionCard(_sections[i]),
                        ),
        ),
      ],
    );
  }

  Widget _stat(AskAideColors c, String value, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c.textMuted),
        const SizedBox(width: 4),
        Text(value,
            style: AppTypography.bodyMedium(c.textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 3),
        Text(label, style: AppTypography.bodySmall(c.textMuted)),
      ],
    );
  }

  Widget _sectionCard(AdminSection s) {
    final c = context.colors;
    final fillRatio =
        s.maxStrength > 0 ? s.currentStrength / s.maxStrength : 0.0;
    final isFull = s.currentStrength >= s.maxStrength && s.maxStrength > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(c.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.isActive
                      ? c.accent.withValues(alpha: 0.12)
                      : c.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  s.isActive ? 'Active' : 'Inactive',
                  style: AppTypography.mono(
                      s.isActive ? c.accent : c.danger, size: 9),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.edit_outlined, size: 17, color: c.textMuted),
                  onPressed: () => _edit(s),
                ),
              ),
              SizedBox(
                width: 32,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.delete_outline, size: 17, color: c.danger),
                  onPressed: () => _delete(s),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.people_outline, size: 13, color: c.textMuted),
              const SizedBox(width: 4),
              Text(
                '${s.currentStrength} / ${s.maxStrength} students',
                style: AppTypography.bodySmall(c.textMuted),
              ),
              const Spacer(),
              Text(
                '${(fillRatio.clamp(0.0, 1.0) * 100).round()}%',
                style: AppTypography.mono(
                    isFull ? c.danger : c.textMuted, size: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillRatio.clamp(0.0, 1.0),
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation(isFull ? c.danger : c.accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Teacher↔student relations for a chosen school. School selector lives inside
/// this panel (not the global header). Filtering opens a bottom sheet with one
/// dropdown per category; active-filter count is shown on the button badge.
