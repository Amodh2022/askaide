import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/confirm_dialog.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/admin_feature.dart';
import '../widgets/admin_overview_panel.dart';

/// `/admin` — institution management. A horizontal tab bar across the admin
/// sections; Schools/Teachers/Students load live with add dialogs. A school
/// selector scopes teacher/student lists. Mirrors AdminDashboard's tabs.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminCubit>(
      create: (_) => sl<AdminCubit>()..init(),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatefulWidget {
  const _AdminView();
  @override
  State<_AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<_AdminView> {
  static const _tabs = [
    'Overview', 'Schools', 'Teachers', 'Students', 'Sections', 'Mappings',
    'Upload', 'Chapters', 'Relations', 'Topics',
  ];
  int _selected = 0;

  /// Tabs that scope by the global header school selector. Schools/Teachers
  /// carry their own picker; the rest read the global selection.
  bool get _usesGlobalSchool {
    final t = _tabs[_selected];
    return t == 'Students' || t == 'Sections' || t == 'Mappings' || t == 'Relations';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // NestedScrollView lets the header (title + school selector) scroll away
    // while the tab chips pin to the top; each panel's own list scrolls below.
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: PageHeader(
                  eyebrow: 'ADMIN PANEL',
                  title: 'Manage your',
                  emphasis: 'institution.',
                  subtitle: 'Schools, teachers, students, and content — all in one place.',
                ),
              ),
              BlocBuilder<AdminCubit, AdminState>(
                buildWhen: (p, n) =>
                    p.schools != n.schools || p.selectedSchoolId != n.selectedSchoolId,
                builder: (context, state) {
                  // Tabs with their own school picker (Schools/Teachers) hide the
                  // global one to avoid a duplicate selector.
                  if (!_usesGlobalSchool || state.schools.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Row(
                      children: [
                        Text('SCHOOL', style: AppTypography.mono(c.textMuted, size: 10)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: state.selectedSchoolId,
                            isExpanded: true,
                            dropdownColor: c.bgCard,
                            style: AppTypography.bodyMedium(c.textPrimary),
                            items: state.schools
                                .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) context.read<AdminCubit>().selectSchool(v);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedTabBar(height: 57, child: _tabStrip(c)),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Container(
          width: double.infinity,
          decoration: context.cardDecoration(),
          child: _panel(_tabs[_selected]),
        ),
      ),
    );
  }

  /// The horizontal pill tab strip; pinned to the top via [_PinnedTabBar].
  Widget _tabStrip(AskAideColors c) {
    return Container(
      color: c.bgPrimary,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = i == _selected;
                return Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? c.accent : c.bgCard,
                        border: Border.all(color: active ? c.accent : c.border),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(_tabs[i],
                          style: AppTypography.bodyMedium(active ? Colors.white : c.textSecondary)),
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Divider(height: 1, color: c.border),
        ],
      ),
    );
  }

  Widget _panel(String tab) {
    switch (tab) {
      case 'Overview':
        return const AdminOverviewPanel();
      case 'Schools':
        return const _SchoolsPanel();
      case 'Teachers':
        return const _TeachersPanel();
      case 'Students':
        return _ListPanel(
          title: 'Students',
          select: (s) => s.students,
          onAdd: () => _addPeopleDialog(
              (rows) => context.read<AdminCubit>().createStudents(rows)),
        );
      case 'Sections':
        return const _SectionsPanel();
      case 'Mappings':
        return const _MappingsPanel();
      case 'Upload':
        return const _CurriculumPanel(mode: _CurriculumMode.upload);
      case 'Chapters':
        return const _CurriculumPanel(mode: _CurriculumMode.chapters);
      case 'Topics':
        return const _CurriculumPanel(mode: _CurriculumMode.topics);
      case 'Relations':
        return const _RelationsPanel();
      default:
        return const EmptyState(
          icon: Icons.table_chart_outlined,
          title: 'Coming soon',
          hint: 'This section connects to the admin API in a later pass.',
        );
    }
  }

  /// Multi-row add for teachers/students (mirrors React `useFieldArray`):
  /// add/remove rows, auto-generate a password per row.
  Future<void> _addPeopleDialog(
      Future<bool> Function(List<Map<String, dynamic>>) onSubmit) async {
    final c = context.colors;
    final rows = <_PersonRow>[_PersonRow()];
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) => AlertDialog(
          backgroundColor: c.bgCard,
          title: Text('Add (${rows.length})', style: AppTypography.h4(c.textPrimary)),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    Row(
                      children: [
                        Text('#${i + 1}', style: AppTypography.mono(c.textMuted, size: 11)),
                        const Spacer(),
                        if (rows.length > 1)
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: c.danger),
                            onPressed: () => setLocal(() => rows.removeAt(i)),
                          ),
                      ],
                    ),
                    TextField(controller: rows[i].name, decoration: const InputDecoration(labelText: 'Name')),
                    TextField(controller: rows[i].email, decoration: const InputDecoration(labelText: 'Email')),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                              controller: rows[i].password,
                              decoration: const InputDecoration(labelText: 'Password')),
                        ),
                        IconButton(
                          tooltip: 'Generate',
                          icon: Icon(Icons.casino_outlined, size: 18, color: c.accent),
                          onPressed: () => setLocal(() => rows[i].password.text = _genPassword()),
                        ),
                      ],
                    ),
                    TextField(controller: rows[i].phone, decoration: const InputDecoration(labelText: 'Phone')),
                    const Divider(height: 24),
                  ],
                  TextButton.icon(
                    onPressed: () => setLocal(() => rows.add(_PersonRow())),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add another'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final payload = [
        for (final r in rows)
          if (r.name.text.trim().isNotEmpty && r.email.text.trim().isNotEmpty)
            {
              'name': r.name.text.trim(),
              'email': r.email.text.trim(),
              'password': r.password.text.trim(),
              if (r.phone.text.trim().isNotEmpty) 'phone': r.phone.text.trim(),
            },
      ];
      final success = payload.isNotEmpty && await onSubmit(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? 'Added ${payload.length}' : 'Could not add')));
      }
    }
    for (final r in rows) {
      r.dispose();
    }
  }

  String _genPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final seed = DateTime.now().microsecondsSinceEpoch;
    final buf = StringBuffer();
    var x = seed;
    for (var i = 0; i < 8; i++) {
      x = x * 1103515245 + 12345;
      buf.write(chars[(x.abs() ~/ 65536) % chars.length]);
    }
    return '${buf.toString()}Aa1!';
  }
}

/// One editable person row inside [_addPeopleDialog].
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

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.title, required this.select, this.onAdd});
  final String title;
  final List<AdminRecord> Function(AdminState) select;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
              if (onAdd != null)
                FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                      backgroundColor: c.accent, foregroundColor: Colors.white),
                  child: const Text('Add'),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: c.border),
        Expanded(
          child: BlocBuilder<AdminCubit, AdminState>(
            builder: (context, state) {
              if (state.status == ALoad.loading) {
                return const SkeletonListLoader();
              }
              final items = select(state);
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No records',
                  hint: 'Add one with the button above.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: c.borderSubtle),
                itemBuilder: (context, i) => ListTile(
                  title: Text(items[i].name, style: AppTypography.bodyMedium(c.textPrimary)),
                  subtitle: items[i].subtitle.isEmpty
                      ? null
                      : Text(items[i].subtitle, style: AppTypography.bodySmall(c.textMuted)),
                ),
              );
            },
          ),
        ),
      ],
    );
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
  final ValueChanged<String?> onClass;
  final ValueChanged<String?> onSubject;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget dd(String label, String? value, List<AdminRecord> items, ValueChanged<String?> on) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: Text(label, style: AppTypography.bodyMedium(c.textMuted)),
                dropdownColor: c.bgCard,
                style: AppTypography.bodyMedium(c.textPrimary),
                items: [
                  for (final it in items)
                    DropdownMenuItem(value: it.id, child: Text(it.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: on,
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        dd('Select class', classId, classes, onClass),
        const SizedBox(width: 12),
        dd('Select subject', subjectId, subjects, onSubject),
      ]),
    );
  }
}

enum _CurriculumMode { chapters, upload, topics }

/// Class/subject-scoped curriculum management: list & delete chapters, create a
/// chapter (Upload), or browse topics. Mirrors ChapterManagement / ChapterUpload
/// / ChapterTopicView.
class _CurriculumPanel extends StatefulWidget {
  const _CurriculumPanel({required this.mode});
  final _CurriculumMode mode;
  @override
  State<_CurriculumPanel> createState() => _CurriculumPanelState();
}

class _CurriculumPanelState extends State<_CurriculumPanel> {
  final _repo = sl<AdminRepository>();
  String? _classId;
  String? _subjectId;
  List<AdminRecord> _subjects = const [];
  List<AdminRecord> _items = const [];
  final Set<String> _selected = {};
  bool _loading = false;

  bool get _isChapters => widget.mode == _CurriculumMode.chapters;

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
      _items = const [];
      _selected.clear();
    });
    final r = await _repo.subjects(classId);
    if (!mounted) return;
    setState(() => _subjects = r.getOrElse(() => const []));
  }

  Future<void> _loadItems(String subjectId) async {
    setState(() {
      _subjectId = subjectId;
      _loading = true;
      _items = const [];
      _selected.clear();
    });
    final classId = _classId!;
    final r = widget.mode == _CurriculumMode.topics
        ? await _repo.topics(classId, subjectId)
        : await _repo.chapters(classId, subjectId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = r.getOrElse(() => const []);
    });
  }

  Future<void> _addChapter() async {
    final nameCtl = TextEditingController();
    final orderCtl = TextEditingController();
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: c.bgCard,
        title: Text('Add chapter', style: AppTypography.h4(c.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Chapter name')),
          const SizedBox(height: 10),
          TextField(
              controller: orderCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Order')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true && _classId != null && _subjectId != null) {
      final r = await _repo.createChapter(
          _classId!, _subjectId!, nameCtl.text.trim(), int.tryParse(orderCtl.text.trim()) ?? 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r.isRight() ? 'Chapter created' : 'Could not create chapter')));
        if (r.isRight()) _loadItems(_subjectId!);
      }
    }
    nameCtl.dispose();
    orderCtl.dispose();
  }

  Future<void> _deleteChapter(String id) async {
    final r = await _repo.deleteChapters(_classId!, _subjectId!, [id]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.isRight() ? 'Deleted' : 'Could not delete')));
      if (r.isRight()) _loadItems(_subjectId!);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_items.map((e) => e.id));
      }
    });
  }

  /// Bulk-deletes the checked chapters (mirrors React ChapterManagement's
  /// multi-select delete with a confirm dialog + count).
  Future<void> _bulkDelete() async {
    final n = _selected.length;
    final ok = await showConfirmDialog(context,
        title: 'Delete chapters',
        message: 'Delete $n chapter(s)? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok) return;
    final r = await _repo.deleteChapters(_classId!, _subjectId!, _selected.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.isRight() ? 'Deleted $n chapter(s)' : 'Could not delete')));
      if (r.isRight()) {
        setState(() => _selected.clear());
        _loadItems(_subjectId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final classes = context.watch<AdminCubit>().state.classes;
    final isTopics = widget.mode == _CurriculumMode.topics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClassSubjectSelector(
          classes: classes,
          classId: _classId,
          subjects: _subjects,
          subjectId: _subjectId,
          onClass: (v) => v != null ? _loadSubjects(v) : null,
          onSubject: (v) => v != null ? _loadItems(v) : null,
        ),
        if (widget.mode != _CurriculumMode.topics && _subjectId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _addChapter,
                icon: const Icon(Icons.add, size: 16),
                label: Text(widget.mode == _CurriculumMode.upload ? 'Create chapter' : 'Add chapter'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
            ),
          ),
        if (_isChapters && _subjectId != null && _items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: _selected.isEmpty
                      ? false
                      : (_selected.length == _items.length ? true : null),
                  activeColor: c.accent,
                  onChanged: (_) => _toggleSelectAll(),
                ),
                Text('Select all', style: AppTypography.bodySmall(c.textSecondary)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _loadItems(_subjectId!),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
                if (_selected.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _bulkDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text('Delete (${_selected.length})'),
                    style: FilledButton.styleFrom(
                        backgroundColor: c.danger, foregroundColor: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        Divider(height: 1, color: c.border),
        Expanded(
          child: _subjectId == null
              ? EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: isTopics ? 'Pick a class & subject' : 'Pick a class & subject',
                  hint: 'Select above to ${isTopics ? 'browse topics' : 'manage chapters'}.',
                )
              : _loading
                  ? const SkeletonListLoader()
                  : _items.isEmpty
                      ? EmptyState(
                          icon: Icons.inbox_outlined,
                          title: isTopics ? 'No topics' : 'No chapters',
                          hint: isTopics
                              ? 'This subject has no topics yet.'
                              : 'Create one with the button above.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: c.borderSubtle),
                          itemBuilder: (context, i) => ListTile(
                            leading: _isChapters
                                ? Checkbox(
                                    value: _selected.contains(_items[i].id),
                                    activeColor: c.accent,
                                    onChanged: (v) => setState(() => v == true
                                        ? _selected.add(_items[i].id)
                                        : _selected.remove(_items[i].id)),
                                  )
                                : null,
                            title: Text(_items[i].name, style: AppTypography.bodyMedium(c.textPrimary)),
                            subtitle: _items[i].subtitle.isEmpty
                                ? null
                                : Text(_items[i].subtitle, style: AppTypography.bodySmall(c.textMuted)),
                            trailing: widget.mode == _CurriculumMode.upload
                                ? IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                                    onPressed: () => _deleteChapter(_items[i].id),
                                  )
                                : null,
                          ),
                        ),
        ),
      ],
    );
  }
}

/// Teachers tab — faithful port of React `TeacherManagement`: a school picker,
/// a multi-row "Add New Teachers" form (wand auto-generates email + password,
/// add/remove rows, validation), and a teachers table with inline edit + delete.
/// Responsive: the form rows and the list collapse to stacked cards on mobile.
class _TeachersPanel extends StatefulWidget {
  const _TeachersPanel();
  @override
  State<_TeachersPanel> createState() => _TeachersPanelState();
}

class _TeachersPanelState extends State<_TeachersPanel> {
  final _formKey = GlobalKey<FormState>();
  List<_PersonRow> _rows = [_PersonRow()];
  bool _creating = false;

  String? _editingId;
  final _editName = TextEditingController();
  final _editEmail = TextEditingController();
  bool _editSaving = false;
  String? _deletingId;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _editName.dispose();
    _editEmail.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _genPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    var x = DateTime.now().microsecondsSinceEpoch;
    final b = StringBuffer();
    for (var i = 0; i < 8; i++) {
      x = x * 1103515245 + 12345;
      b.write(chars[(x.abs() ~/ 65536) % chars.length]);
    }
    return '${b}Aa1!';
  }

  void _generate(int i) {
    final name = _rows[i].name.text.trim();
    if (name.isEmpty) {
      _snack('Please enter a name first');
      return;
    }
    final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final rand = DateTime.now().microsecondsSinceEpoch % 1000;
    setState(() {
      _rows[i].email.text = '$clean.$rand@school.com';
      _rows[i].password.text = _genPassword();
    });
    _snack('Credentials generated!');
  }

  Future<void> _submit() async {
    final schoolId = context.read<AdminCubit>().state.selectedSchoolId;
    if (schoolId == null) {
      _snack('Please select a school first');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    final payload = [
      for (final r in _rows)
        {
          'name': r.name.text.trim(),
          'email': r.email.text.trim(),
          'password': r.password.text.trim(),
          if (r.phone.text.trim().isNotEmpty) 'phone': r.phone.text.trim(),
        }
    ];
    final n = payload.length;
    final ok = await context.read<AdminCubit>().createTeachers(payload);
    if (!mounted) return;
    setState(() => _creating = false);
    _snack(ok ? 'Successfully created $n teacher${n != 1 ? 's' : ''}' : 'Failed to create teachers');
    if (ok) {
      setState(() {
        for (final r in _rows) {
          r.dispose();
        }
        _rows = [_PersonRow()];
      });
    }
  }

  void _openEdit(AdminRecord t) => setState(() {
        _editingId = t.id;
        _editName.text = t.name;
        _editEmail.text = t.subtitle;
      });

  Future<void> _saveEdit(String id) async {
    if (_editName.text.trim().isEmpty || _editEmail.text.trim().isEmpty) {
      _snack('Name and email are required');
      return;
    }
    setState(() => _editSaving = true);
    final ok = await context.read<AdminCubit>().updateTeacher(id, {
      'name': _editName.text.trim(),
      'email': _editEmail.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _editSaving = false;
      if (ok) _editingId = null;
    });
    _snack(ok ? 'Teacher updated' : 'Failed to update teacher');
  }

  Future<void> _delete(String id) async {
    setState(() => _deletingId = id);
    await context.read<AdminCubit>().deleteTeacher(id);
    if (mounted) setState(() => _deletingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    final hasSchool = state.selectedSchoolId != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Teacher Management', style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        _createCard(c, state, hasSchool),
        if (hasSchool) ...[
          const SizedBox(height: 16),
          _listCard(c, state.teachers),
        ],
      ],
    );
  }

  // ── Create card ──
  Widget _createCard(AskAideColors c, AdminState state, bool hasSchool) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SELECT SCHOOL', style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: state.selectedSchoolId,
                hint: Text('-- Select a School --', style: AppTypography.bodyMedium(c.textMuted)),
                dropdownColor: c.bgCard,
                style: AppTypography.bodyMedium(c.textPrimary),
                items: [
                  for (final s in state.schools)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        s.subtitle.isEmpty ? s.name : '${s.name} (${s.subtitle})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) context.read<AdminCubit>().selectSchool(v);
                },
              ),
            ),
          ),
          if (hasSchool) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add New Teachers', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                TextButton.icon(
                  onPressed: () => setState(() => _rows.add(_PersonRow())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            Divider(height: 16, color: c.border),
            Form(
              key: _formKey,
              child: Column(
                children: [for (var i = 0; i < _rows.length; i++) _createRow(c, i)],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _creating ? null : _submit,
                icon: _creating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: Text('Create ${_rows.length} Teacher${_rows.length != 1 ? 's' : ''}'),
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _createRow(AskAideColors c, int i) {
    final r = _rows[i];
    final mobile = context.isMobile;
    final nameField = _tf(c, 'Full Name *', r.name,
        hint: 'John Doe',
        requiredField: true,
        trailing: IconButton(
          tooltip: 'Auto-generate email & password',
          onPressed: () => _generate(i),
          icon: Icon(Icons.auto_fix_high, size: 18, color: c.accent),
        ));
    final emailField = _tf(c, 'Email *', r.email, hint: 'john@school.com', requiredField: true, email: true);
    final passField = _tf(c, 'Password *', r.password, hint: 'Secret123!', requiredField: true, minLen: 6);
    final phoneField = _tf(c, 'Phone', r.phone, hint: '+1234567890');
    final remove = _rows.length > 1
        ? IconButton(
            onPressed: () => setState(() => _rows.removeAt(i).dispose()),
            icon: Icon(Icons.delete_outline, size: 18, color: c.textMuted),
          )
        : const SizedBox(width: 40);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_rows.length > 1)
                  Align(alignment: Alignment.centerRight, child: remove),
                nameField,
                const SizedBox(height: 10),
                emailField,
                const SizedBox(height: 10),
                passField,
                const SizedBox(height: 10),
                phoneField,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: nameField),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: emailField),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: passField),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: phoneField),
                Padding(padding: const EdgeInsets.only(top: 20), child: remove),
              ],
            ),
    );
  }

  Widget _tf(AskAideColors c, String label, TextEditingController ctl,
      {String? hint, bool requiredField = false, bool email = false, int? minLen, Widget? trailing}) {
    final field = TextFormField(
      controller: ctl,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      style: AppTypography.bodySmall(c.textPrimary),
      decoration: InputDecoration(hintText: hint, isDense: true),
      validator: (v) {
        final t = (v ?? '').trim();
        if (requiredField && t.isEmpty) return 'Required';
        if (email && t.isNotEmpty && !RegExp(r'^\S+@\S+$').hasMatch(t)) return 'Invalid';
        if (minLen != null && t.isNotEmpty && t.length < minLen) return 'Min $minLen';
        return null;
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        trailing == null
            ? field
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: field),
                trailing,
              ]),
      ],
    );
  }

  // ── List card ──
  Widget _listCard(AskAideColors c, List<AdminRecord> teachers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('Teachers', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
            const SizedBox(width: 8),
            Text('(${teachers.length})', style: AppTypography.bodySmall(c.textMuted)),
          ]),
          const SizedBox(height: 12),
          if (teachers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: Icons.people_outline,
                title: 'No Teachers Found',
                hint: 'Add teachers with the form above.',
              ),
            )
          else if (context.isMobile)
            Column(children: [for (final t in teachers) _teacherCardMobile(c, t)])
          else ...[
            Row(children: [
              Expanded(flex: 4, child: Text('NAME', style: AppTypography.mono(c.textMuted, size: 10))),
              Expanded(flex: 5, child: Text('EMAIL', style: AppTypography.mono(c.textMuted, size: 10))),
              SizedBox(width: 96, child: Text('ACTIONS', textAlign: TextAlign.right, style: AppTypography.mono(c.textMuted, size: 10))),
            ]),
            Divider(height: 12, color: c.border),
            for (final t in teachers) _teacherRowDesktop(c, t),
          ],
        ],
      ),
    );
  }

  Widget _teacherRowDesktop(AskAideColors c, AdminRecord t) {
    final editing = _editingId == t.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: editing
                ? _inlineField(c, _editName)
                : Text(t.name, style: AppTypography.bodyMedium(c.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: editing
                ? _inlineField(c, _editEmail)
                : Text(t.subtitle, style: AppTypography.bodySmall(c.textSecondary)),
          ),
          SizedBox(width: 96, child: _actions(c, t, editing)),
        ],
      ),
    );
  }

  Widget _teacherCardMobile(AskAideColors c, AdminRecord t) {
    final editing = _editingId == t.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: editing
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _inlineField(c, _editName),
              const SizedBox(height: 8),
              _inlineField(c, _editEmail),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: _actions(c, t, true)),
            ])
          : Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.name, style: AppTypography.bodyMedium(c.textPrimary)),
                  Text(t.subtitle, style: AppTypography.bodySmall(c.textMuted)),
                ]),
              ),
              _actions(c, t, false),
            ]),
    );
  }

  Widget _inlineField(AskAideColors c, TextEditingController ctl) => TextField(
        controller: ctl,
        style: AppTypography.bodySmall(c.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
        ),
      );

  Widget _actions(AskAideColors c, AdminRecord t, bool editing) {
    if (editing) {
      return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
        IconButton(
          onPressed: _editSaving ? null : () => _saveEdit(t.id),
          icon: _editSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.check, size: 18, color: c.success),
        ),
        IconButton(
          onPressed: () => setState(() => _editingId = null),
          icon: Icon(Icons.close, size: 18, color: c.textMuted),
        ),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(
        onPressed: () => _openEdit(t),
        icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
      ),
      IconButton(
        onPressed: _deletingId == t.id ? null : () => _delete(t.id),
        icon: _deletingId == t.id
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.delete_outline, size: 18, color: c.danger),
      ),
    ]);
  }
}

/// Schools tab — faithful port of React `SchoolManagement`: a header with an
/// "Add School" button, an inline create/edit form (7 fields on create, just
/// name + code on edit), and a responsive card grid with per-card edit.
class _SchoolsPanel extends StatefulWidget {
  const _SchoolsPanel();
  @override
  State<_SchoolsPanel> createState() => _SchoolsPanelState();
}

class _SchoolsPanelState extends State<_SchoolsPanel> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _address = TextEditingController();
  final _board = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();

  bool _isCreating = false;
  AdminRecord? _editing;
  bool _saving = false;

  bool get _formOpen => _isCreating || _editing != null;

  List<TextEditingController> get _all =>
      [_name, _code, _address, _board, _phone, _email, _website];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetFields() {
    for (final c in _all) {
      c.clear();
    }
  }

  void _startCreate() => setState(() {
        _editing = null;
        _isCreating = true;
        _resetFields();
      });

  void _startEdit(AdminRecord s) => setState(() {
        _editing = s;
        _isCreating = false;
        _resetFields();
        _name.text = s.name;
        _code.text = s.subtitle;
      });

  void _cancel() => setState(() {
        _editing = null;
        _isCreating = false;
        _resetFields();
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final cubit = context.read<AdminCubit>();
    final editing = _editing;
    final bool ok;
    if (editing != null) {
      ok = await cubit.updateSchool(editing.id, {
        'schoolName': _name.text.trim(),
        'schoolCode': _code.text.trim(),
      });
    } else {
      ok = await cubit.createSchool({
        'schoolName': _name.text.trim(),
        'schoolCode': _code.text.trim(),
        'schoolAddress': _address.text.trim(),
        'schoolBoard': _board.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'schoolPhone': _phone.text.trim(),
        if (_email.text.trim().isNotEmpty) 'schoolEmail': _email.text.trim(),
        if (_website.text.trim().isNotEmpty) 'schoolWebsite': _website.text.trim(),
      });
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (editing != null ? 'School updated successfully' : 'School created successfully')
            : 'Operation failed')));
    if (ok) _cancel();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
                child: Text('School Management',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22))),
            if (!_formOpen)
              FilledButton.icon(
                onPressed: _startCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add School'),
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
          ],
        ),
        if (_formOpen) ...[
          const SizedBox(height: 16),
          _formCard(c),
        ],
        const SizedBox(height: 16),
        if (state.status == ALoad.loading && state.schools.isEmpty)
          const SkeletonListLoader()
        else
          _grid(c, state.schools),
      ],
    );
  }

  Widget _formCard(AskAideColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_editing != null ? 'Edit School' : 'Create New School',
                    style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                IconButton(onPressed: _cancel, icon: Icon(Icons.close, size: 20, color: c.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth > 520 ? (box.maxWidth - 12) / 2 : box.maxWidth;
              final fields = <Widget>[
                _field(c, 'School Name *', _name, hint: 'e.g. Greenwood High', requiredMsg: 'School Name is required'),
                _field(c, 'School Code *', _code, hint: 'e.g. GW001', requiredMsg: 'School Code is required'),
                if (_editing == null) ...[
                  _field(c, 'Address *', _address, requiredMsg: 'Address is required'),
                  _field(c, 'Board *', _board, hint: 'e.g. CBSE', requiredMsg: 'Board is required'),
                  _field(c, 'Phone', _phone),
                  _field(c, 'Email', _email, email: true),
                  _field(c, 'Website', _website),
                ],
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final f in fields) SizedBox(width: w, child: f)],
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _cancel, child: Text('Cancel', style: AppTypography.button(c.textSecondary))),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, size: 18),
                  label: Text(_editing != null ? 'Update School' : 'Create School'),
                  style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(AskAideColors c, String label, TextEditingController ctl,
      {String? hint, String? requiredMsg, bool email = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.mono(c.textSecondary, size: 10)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctl,
          keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(hintText: hint),
          validator: (v) {
            final t = (v ?? '').trim();
            if (requiredMsg != null && t.isEmpty) return requiredMsg;
            if (email && t.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _grid(AskAideColors c, List<AdminRecord> schools) {
    if (schools.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: EmptyState(
          icon: Icons.school_outlined,
          title: 'No schools',
          hint: 'Add one with the button above.',
        ),
      );
    }
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth > 900 ? 3 : (box.maxWidth > 600 ? 2 : 1);
      final w = (box.maxWidth - 16 * (cols - 1)) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final s in schools)
            SizedBox(width: cols == 1 ? box.maxWidth : w, child: _card(c, s)),
        ],
      );
    });
  }

  Widget _card(AskAideColors c, AdminRecord s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text('Code: ${s.subtitle}', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _startEdit(s),
            icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Class-scoped section management: list (strength + active badge), single &
/// bulk create, edit (max strength + active), delete with confirm. Mirrors
/// React SectionManagement.
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: c.bgCard,
        title: Text('Add section', style: AppTypography.h4(c.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Section name (e.g. A)')),
          const SizedBox(height: 10),
          TextField(
              controller: maxCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max strength')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true && _schoolId != null && _classId != null) {
      final r = await _repo.createSection(nameCtl.text.trim(), _schoolId!,
          classId: _classId, maxStrength: int.tryParse(maxCtl.text.trim()));
      _after(r.isRight(), 'Section created', 'Could not create section');
    }
    nameCtl.dispose();
    maxCtl.dispose();
  }

  Future<void> _addBulk() async {
    final c = context.colors;
    final ctl = TextEditingController(text: 'A, B, C, D');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: c.bgCard,
        title: Text('Bulk add sections', style: AppTypography.h4(c.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: ctl,
              decoration: const InputDecoration(labelText: 'Section names (comma-separated)')),
          const SizedBox(height: 8),
          Text('Existing sections will be skipped.',
              style: AppTypography.bodySmall(c.textMuted)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true && _schoolId != null && _classId != null) {
      final names = ctl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (names.isNotEmpty) {
        final r = await _repo.createSectionsBulk(_schoolId!, _classId!, names);
        _after(r.isRight(), 'Created ${names.length} sections', 'Could not create sections');
      }
    }
    ctl.dispose();
  }

  Future<void> _edit(AdminSection s) async {
    final c = context.colors;
    final nameCtl = TextEditingController(text: s.name);
    final maxCtl = TextEditingController(text: '${s.maxStrength}');
    var active = s.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) => AlertDialog(
          backgroundColor: c.bgCard,
          title: Text('Edit section', style: AppTypography.h4(c.textPrimary)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
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
              onChanged: (v) => setLocal(() => active = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final r = await _repo.updateSection(s.id, {
        'name': nameCtl.text.trim(),
        'maxStrength': int.tryParse(maxCtl.text.trim()) ?? s.maxStrength,
        'isActive': active,
      });
      _after(r.isRight(), 'Section updated', 'Could not update section');
    }
    nameCtl.dispose();
    maxCtl.dispose();
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
    if (state.selectedSchoolId == null) {
      return const EmptyState(
        icon: Icons.layers_outlined,
        title: 'Select a school',
        hint: 'Choose a school above to manage sections.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _classId,
                hint: Text('Select class', style: AppTypography.bodyMedium(c.textMuted)),
                dropdownColor: c.bgCard,
                style: AppTypography.bodyMedium(c.textPrimary),
                items: [
                  for (final cl in state.classes)
                    DropdownMenuItem(value: cl.id, child: Text(cl.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => v != null ? _selectClass(v) : null,
              ),
            ),
          ),
        ),
        if (_classId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _sections.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: c.borderSubtle),
                          itemBuilder: (context, i) {
                            final s = _sections[i];
                            return ListTile(
                              title: Row(children: [
                                Flexible(
                                    child: Text(s.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyMedium(c.textPrimary))),
                                if (!s.isActive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.danger.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('Inactive', style: AppTypography.mono(c.danger, size: 9)),
                                  ),
                                ],
                              ]),
                              subtitle: Text('${s.currentStrength} / ${s.maxStrength}',
                                  style: AppTypography.bodySmall(c.textMuted)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
                                    onPressed: () => _edit(s),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                                    onPressed: () => _delete(s),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

/// Filterable teacher↔student relations table for the selected school. Mirrors
/// React RelationView: 5 columns (teacher/student with email, class, section,
/// subject) and 4 dynamic dropdown filters with a record count.
class _RelationsPanel extends StatefulWidget {
  const _RelationsPanel();
  @override
  State<_RelationsPanel> createState() => _RelationsPanelState();
}

class _RelationsPanelState extends State<_RelationsPanel> {
  final _repo = sl<AdminRepository>();
  List<AdminLink> _links = const [];
  bool _loading = false;
  String? _loadedFor;
  String _fTeacher = '', _fClass = '', _fSubject = '', _fSection = '';

  Future<void> _load(String schoolId) async {
    setState(() {
      _loading = true;
      _loadedFor = schoolId;
    });
    final r = await _repo.teacherStudentLinksDetailed(schoolId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _links = r.getOrElse(() => const []);
    });
  }

  List<String> _uniq(String Function(AdminLink) sel) {
    final set = <String>{for (final l in _links) if (sel(l).isNotEmpty) sel(l)};
    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final schoolId = context.watch<AdminCubit>().state.selectedSchoolId;
    if (schoolId != null && schoolId != _loadedFor && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && schoolId != _loadedFor) _load(schoolId);
      });
    }
    if (schoolId == null) {
      return const EmptyState(
        icon: Icons.account_tree_outlined,
        title: 'Select a school',
        hint: 'Choose a school above to view its teacher–student relations.',
      );
    }
    if (_loading) return const SkeletonListLoader();

    final filtered = _links
        .where((l) =>
            (_fTeacher.isEmpty || l.teacherName == _fTeacher) &&
            (_fClass.isEmpty || l.className == _fClass) &&
            (_fSubject.isEmpty || l.subjectName == _fSubject) &&
            (_fSection.isEmpty || l.sectionName == _fSection))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _filter(c, 'All teachers', _fTeacher, _uniq((l) => l.teacherName), (v) => setState(() => _fTeacher = v)),
            _filter(c, 'All classes', _fClass, _uniq((l) => l.className), (v) => setState(() => _fClass = v)),
            _filter(c, 'All subjects', _fSubject, _uniq((l) => l.subjectName), (v) => setState(() => _fSubject = v)),
            _filter(c, 'All sections', _fSection, _uniq((l) => l.sectionName), (v) => setState(() => _fSection = v)),
          ]),
        ),
        Divider(height: 1, color: c.border),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.account_tree_outlined,
                  title: 'No records',
                  hint: 'No records match your current filters.',
                )
              : SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: AppTypography.mono(c.textMuted, size: 10),
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
                            DataCell(_who(c, l.studentName, l.studentEmail)),
                            DataCell(Text(l.className.isEmpty ? '—' : l.className,
                                style: AppTypography.bodySmall(c.textPrimary))),
                            DataCell(l.sectionName.isEmpty
                                ? Text('—', style: AppTypography.bodySmall(c.textMuted))
                                : _sectionBadge(c, l.sectionName)),
                            DataCell(Text(l.subjectName.isEmpty ? '—' : l.subjectName,
                                style: AppTypography.bodySmall(c.textPrimary))),
                          ]),
                      ],
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Showing ${filtered.length} records',
              style: AppTypography.bodySmall(c.textMuted)),
        ),
      ],
    );
  }

  Widget _who(AskAideColors c, String name, String email) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTypography.bodyMedium(c.textPrimary)),
          if (email.isNotEmpty) Text(email, style: AppTypography.bodySmall(c.textMuted)),
        ],
      );

  Widget _sectionBadge(AskAideColors c, String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c.accentLight, borderRadius: BorderRadius.circular(99)),
        child: Text(name, style: AppTypography.bodySmall(c.accent)),
      );

  Widget _filter(AskAideColors c, String allLabel, String value, List<String> options,
      ValueChanged<String> onChanged) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text(allLabel, style: AppTypography.bodySmall(c.textMuted)),
          isDense: true,
          dropdownColor: c.bgCard,
          style: AppTypography.bodySmall(c.textPrimary),
          onChanged: (v) => onChanged(v ?? ''),
          items: [
            DropdownMenuItem(value: '', child: Text(allLabel)),
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Create teacher → student mappings within the selected school.
class _MappingsPanel extends StatefulWidget {
  const _MappingsPanel();
  @override
  State<_MappingsPanel> createState() => _MappingsPanelState();
}

class _MappingsPanelState extends State<_MappingsPanel> {
  final _repo = sl<AdminRepository>();
  String? _teacherId;
  final Set<String> _studentIds = {};
  String? _sectionId;
  String? _classId;
  String? _subjectId;
  List<AdminRecord> _subjects = const [];
  bool _saving = false;

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
    });
    final r = await _repo.subjects(classId);
    if (mounted) setState(() => _subjects = r.getOrElse(() => const []));
  }

  Future<void> _submit(AdminState state) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null ||
        _teacherId == null ||
        _classId == null ||
        _subjectId == null ||
        _studentIds.isEmpty) {
      return;
    }
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
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.isRight() ? 'Mapping created' : 'Could not create mapping')));
    if (r.isRight()) setState(() => _studentIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    if (state.selectedSchoolId == null) {
      return const EmptyState(
        icon: Icons.hub_outlined,
        title: 'Select a school',
        hint: 'Choose a school above to map teachers to students.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEACHER', style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _teacherId,
                hint: Text('Select teacher', style: AppTypography.bodyMedium(c.textMuted)),
                dropdownColor: c.bgCard,
                style: AppTypography.bodyMedium(c.textPrimary),
                items: [
                  for (final t in state.teachers)
                    DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _teacherId = v),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('CLASS', style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _classId,
                hint: Text('Select class', style: AppTypography.bodyMedium(c.textMuted)),
                dropdownColor: c.bgCard,
                style: AppTypography.bodyMedium(c.textPrimary),
                items: [
                  for (final cl in state.classes)
                    DropdownMenuItem(value: cl.id, child: Text(cl.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => v != null ? _loadSubjects(v) : null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('SUBJECT', style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _subjectId,
                hint: Text(_classId == null ? 'Select class first' : 'Select subject',
                    style: AppTypography.bodyMedium(c.textMuted)),
                dropdownColor: c.bgCard,
                style: AppTypography.bodyMedium(c.textPrimary),
                items: [
                  for (final s in _subjects)
                    DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: _classId == null ? null : (v) => setState(() => _subjectId = v),
              ),
            ),
          ),
          if (state.sections.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('SECTION (optional)', style: AppTypography.mono(c.textMuted, size: 10)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.bgCard,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _sectionId,
                  hint: Text('Select section', style: AppTypography.bodyMedium(c.textMuted)),
                  dropdownColor: c.bgCard,
                  style: AppTypography.bodyMedium(c.textPrimary),
                  items: [
                    for (final s in state.sections)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _sectionId = v),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text('STUDENTS', style: AppTypography.mono(c.textMuted, size: 10)),
          const SizedBox(height: 6),
          if (state.students.isEmpty)
            Text('No students in this school.', style: AppTypography.bodySmall(c.textMuted))
          else
            ...state.students.map((s) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _studentIds.contains(s.id),
                  activeColor: c.accent,
                  title: Text(s.name, style: AppTypography.bodyMedium(c.textPrimary)),
                  subtitle: s.subtitle.isEmpty
                      ? null
                      : Text(s.subtitle, style: AppTypography.bodySmall(c.textMuted)),
                  onChanged: (v) => setState(() {
                    v == true ? _studentIds.add(s.id) : _studentIds.remove(s.id);
                  }),
                )),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_teacherId != null &&
                    _classId != null &&
                    _subjectId != null &&
                    _studentIds.isNotEmpty &&
                    !_saving)
                ? () => _submit(state)
                : null,
            icon: _saving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.link, size: 16),
            label: Text('Map ${_studentIds.length} student(s)'),
            style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
