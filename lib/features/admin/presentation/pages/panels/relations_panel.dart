part of '../admin_dashboard_page.dart';

class _RelationsPanel extends StatefulWidget {
  const _RelationsPanel();
  @override
  State<_RelationsPanel> createState() => _RelationsPanelState();
}

class _RelationsPanelState extends State<_RelationsPanel> {
  final _repo = sl<AdminRepository>();

  String? _schoolId;            // local school selection
  List<AdminLink> _links = const [];
  bool _loading = false;

  // committed filter values (empty = all)
  String _fTeacher = '', _fClass = '', _fSubject = '', _fSection = '';

  int get _activeFilterCount => [_fTeacher, _fClass, _fSubject, _fSection]
      .where((f) => f.isNotEmpty)
      .length;

  Future<void> _load(String schoolId) async {
    setState(() {
      _schoolId = schoolId;
      _loading = true;
      _links = const [];
      _fTeacher = '';
      _fClass = '';
      _fSubject = '';
      _fSection = '';
    });
    final r = await _repo.teacherStudentLinksDetailed(schoolId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _links = r.getOrElse(() => const []);
    });
  }

  List<String> _uniq(String Function(AdminLink) sel) =>
      ({for (final l in _links) if (sel(l).isNotEmpty) sel(l)}.toList()..sort());

  void _openFilterSheet() {
    final c = context.colors;
    // Start from current committed values so re-opening shows last applied state.
    String tmpTeacher = _fTeacher,
        tmpClass = _fClass,
        tmpSubject = _fSubject,
        tmpSection = _fSection;

    final teachers = _uniq((l) => l.teacherName);
    final classes  = _uniq((l) => l.className);
    final subjects = _uniq((l) => l.subjectName);
    final sections = _uniq((l) => l.sectionName);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bsCtx) => StatefulBuilder(
        builder: (ctx, setSt) {
          Widget dd(String label, String value, List<String> opts,
              ValueChanged<String> onChanged) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.bgPrimary,
                    border: Border.all(
                        color: value.isNotEmpty ? c.accent : c.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: value.isEmpty ? null : value,
                      hint: Text('All',
                          style: AppTypography.bodyMedium(c.textMuted)),
                      dropdownColor: c.bgCard,
                      style: AppTypography.bodyMedium(c.textPrimary),
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: value.isNotEmpty ? c.accent : c.textMuted),
                      items: [
                        DropdownMenuItem(
                            value: '',
                            child: Text('All',
                                style: AppTypography.bodyMedium(c.textMuted))),
                        for (final o in opts)
                          DropdownMenuItem(
                              value: o,
                              child: Text(o,
                                  overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setSt(() => onChanged(v ?? '')),
                    ),
                  ),
                ),
              ],
            );
          }

          final tmpCount = [tmpTeacher, tmpClass, tmpSubject, tmpSection]
              .where((f) => f.isNotEmpty)
              .length;

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(bsCtx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle bar ───────────────────────────────────────────
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(99)),
                ),
                const SizedBox(height: 16),

                // ── Sheet header ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('Filter Relations',
                          style: AppTypography.h4(c.textPrimary)
                              .copyWith(fontSize: 18)),
                      const Spacer(),
                      if (tmpCount > 0)
                        TextButton(
                          onPressed: () => setSt(() {
                            tmpTeacher = '';
                            tmpClass = '';
                            tmpSubject = '';
                            tmpSection = '';
                          }),
                          style: TextButton.styleFrom(
                              foregroundColor: c.textMuted,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8)),
                          child: const Text('Clear all'),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(bsCtx),
                        icon: Icon(Icons.close, size: 20, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: c.border),

                // ── Filter dropdowns ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      dd('TEACHER', tmpTeacher, teachers,
                          (v) => tmpTeacher = v),
                      const SizedBox(height: 16),
                      dd('CLASS', tmpClass, classes,
                          (v) => tmpClass = v),
                      const SizedBox(height: 16),
                      dd('SUBJECT', tmpSubject, subjects,
                          (v) => tmpSubject = v),
                      const SizedBox(height: 16),
                      dd('SECTION', tmpSection, sections,
                          (v) => tmpSection = v),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Action buttons ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(bsCtx),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: c.border),
                            foregroundColor: c.textSecondary,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _fTeacher = tmpTeacher;
                              _fClass = tmpClass;
                              _fSubject = tmpSubject;
                              _fSection = tmpSection;
                            });
                            Navigator.pop(bsCtx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: c.accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Text(tmpCount > 0
                              ? 'Apply ($tmpCount)'
                              : 'Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;

    final filtered = _links
        .where((l) =>
            (_fTeacher.isEmpty || l.teacherName == _fTeacher) &&
            (_fClass.isEmpty || l.className == _fClass) &&
            (_fSubject.isEmpty || l.subjectName == _fSubject) &&
            (_fSection.isEmpty || l.sectionName == _fSection))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Page title ───────────────────────────────────────────────────────
        Text('Relation Management',
            style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
        const SizedBox(height: 16),

        // ── School selector card ─────────────────────────────────────────────
        _schoolCard(c, state),
        const SizedBox(height: 16),

        // ── Relations card ───────────────────────────────────────────────────
        if (_schoolId != null) _relationsCard(c, filtered),
      ],
    );
  }

  Widget _schoolCard(AskAideColors c, AdminState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _PickerField(
        label: 'School',
        hint: 'Select a school…',
        items: state.schools
            .map((s) => AdminRecord(
                id: s.id,
                name: s.code.isEmpty ? s.name : '${s.name} (${s.code})'))
            .toList(),
        selectedId: _schoolId,
        onChanged: _load,
      ),
    );
  }

  Widget _relationsCard(AskAideColors c, List<AdminLink> filtered) {
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header ────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('Relations',
                    style: AppTypography.h4(c.textPrimary)
                        .copyWith(fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _loading
                        ? '…'
                        : '${filtered.length} of ${_links.length}',
                    style: AppTypography.mono(c.accent, size: 11),
                  ),
                ),
                const Spacer(),
                // Refresh
                IconButton(
                  onPressed:
                      _loading ? null : () => _load(_schoolId!),
                  icon: Icon(Icons.refresh,
                      size: 18, color: c.textMuted),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 4),
                // Filter button with active-count badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          (_loading || _links.isEmpty) ? null : _openFilterSheet,
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _activeFilterCount > 0
                            ? c.accent
                            : c.textSecondary,
                        side: BorderSide(
                            color: _activeFilterCount > 0
                                ? c.accent
                                : c.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            '$_activeFilterCount',
                            style: AppTypography.mono(Colors.white,
                                size: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),

          // ── Body ───────────────────────────────────────────────────────────
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonListLoader())
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.account_tree_outlined,
                title: _activeFilterCount > 0
                    ? 'No records match filters'
                    : 'No relations yet',
                hint: _activeFilterCount > 0
                    ? 'Try adjusting or clearing the active filters.'
                    : 'Relations will appear once teacher–student links are created.',
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle:
                    AppTypography.mono(c.textMuted, size: 10),
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('TEACHER')),
                  DataColumn(label: Text('STUDENT')),
                  DataColumn(label: Text('CLASS')),
                  DataColumn(label: Text('SECTION')),
                  DataColumn(label: Text('SUBJECT')),
                ],
                rows: [
                  for (final l in filtered)
                    DataRow(cells: [
                      DataCell(_who(c, l.teacherName, l.teacherEmail)),
                      DataCell(
                          _who(c, l.studentName, l.studentEmail)),
                      DataCell(Text(
                          l.className.isEmpty ? '—' : l.className,
                          style:
                              AppTypography.bodySmall(c.textPrimary))),
                      DataCell(l.sectionName.isEmpty
                          ? Text('—',
                              style: AppTypography.bodySmall(
                                  c.textMuted))
                          : _sectionBadge(c, l.sectionName)),
                      DataCell(Text(
                          l.subjectName.isEmpty
                              ? '—'
                              : l.subjectName,
                          style:
                              AppTypography.bodySmall(c.textPrimary))),
                    ]),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _who(AskAideColors c, String name, String email) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium(c.textPrimary)),
          if (email.isNotEmpty)
            Text(email,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(c.textMuted)),
        ],
      );

  Widget _sectionBadge(AskAideColors c, String name) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: c.accentLight,
            borderRadius: BorderRadius.circular(99)),
        child: Text(name, style: AppTypography.bodySmall(c.accent)),
      );
}

/// Create teacher → student mappings within the selected school.
