import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/admin_feature.dart';

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
    'Schools', 'Teachers', 'Students', 'Sections', 'Mappings',
    'Upload', 'Chapters', 'Relations', 'Topics',
  ];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
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
        // School selector
        BlocBuilder<AdminCubit, AdminState>(
          buildWhen: (p, n) => p.schools != n.schools || p.selectedSchoolId != n.selectedSchoolId,
          builder: (context, state) {
            if (state.schools.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Container(
              width: double.infinity,
              decoration: context.cardDecoration(),
              child: _panel(_tabs[_selected]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panel(String tab) {
    switch (tab) {
      case 'Schools':
        return _ListPanel(
          title: 'Schools',
          select: (s) => s.schools,
          onAdd: () => _addDialog(['School name', 'School code', 'Address'], (v) =>
              context.read<AdminCubit>().createSchool(v[0], v[1], v[2])),
        );
      case 'Teachers':
        return _ListPanel(
          title: 'Teachers',
          select: (s) => s.teachers,
          onAdd: () => _addDialog(['Name', 'Email', 'Password', 'Phone'], (v) =>
              context.read<AdminCubit>().createTeacher(v[0], v[1], v[2], v[3])),
          onDelete: (id) => context.read<AdminCubit>().deleteTeacher(id),
        );
      case 'Students':
        return _ListPanel(
          title: 'Students',
          select: (s) => s.students,
          onAdd: () => _addDialog(['Name', 'Email', 'Password', 'Phone'], (v) =>
              context.read<AdminCubit>().createStudent(v[0], v[1], v[2], v[3])),
        );
      case 'Sections':
        return _ListPanel(
          title: 'Sections',
          select: (s) => s.sections,
          onAdd: () => _addDialog(['Section name', 'Max strength'], (v) =>
              context.read<AdminCubit>().createSection(v[0],
                  maxStrength: int.tryParse(v[1]))),
          onDelete: (id) => context.read<AdminCubit>().deleteSection(id),
        );
      case 'Classes':
        return _ListPanel(title: 'Classes', select: (s) => s.classes);
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

  Future<void> _addDialog(List<String> fields, Future<bool> Function(List<String>) onSubmit) async {
    final controllers = [for (final _ in fields) TextEditingController()];
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.bgCard,
        title: Text('Add', style: AppTypography.h4(c.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < fields.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(labelText: fields[i]),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      final success = await onSubmit(controllers.map((e) => e.text.trim()).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? 'Added' : 'Could not add')));
      }
    }
    for (final ctl in controllers) {
      ctl.dispose();
    }
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.title, required this.select, this.onAdd, this.onDelete});
  final String title;
  final List<AdminRecord> Function(AdminState) select;
  final VoidCallback? onAdd;
  final void Function(String id)? onDelete;

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
                  trailing: onDelete == null
                      ? null
                      : IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                          onPressed: () => onDelete!(items[i].id),
                        ),
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
  bool _loading = false;

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
      _items = const [];
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
                            title: Text(_items[i].name, style: AppTypography.bodyMedium(c.textPrimary)),
                            subtitle: _items[i].subtitle.isEmpty
                                ? null
                                : Text(_items[i].subtitle, style: AppTypography.bodySmall(c.textMuted)),
                            trailing: isTopics
                                ? null
                                : IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                                    onPressed: () => _deleteChapter(_items[i].id),
                                  ),
                          ),
                        ),
        ),
      ],
    );
  }
}

/// Read-only teacher → student relations for the selected school.
class _RelationsPanel extends StatefulWidget {
  const _RelationsPanel();
  @override
  State<_RelationsPanel> createState() => _RelationsPanelState();
}

class _RelationsPanelState extends State<_RelationsPanel> {
  final _repo = sl<AdminRepository>();
  List<AdminRecord> _links = const [];
  bool _loading = false;
  String? _loadedFor;

  Future<void> _load(String schoolId) async {
    setState(() {
      _loading = true;
      _loadedFor = schoolId;
    });
    final r = await _repo.teacherStudentLinks(schoolId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _links = r.getOrElse(() => const []);
    });
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
    if (_links.isEmpty) {
      return const EmptyState(
        icon: Icons.account_tree_outlined,
        title: 'No relations',
        hint: 'No teacher–student links exist for this school yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _links.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: c.borderSubtle),
      itemBuilder: (context, i) => ListTile(
        leading: Icon(Icons.link, size: 18, color: c.accent),
        title: Text(_links[i].name, style: AppTypography.bodyMedium(c.textPrimary)),
        subtitle: Text(_links[i].subtitle, style: AppTypography.bodySmall(c.textMuted)),
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
  bool _saving = false;

  Future<void> _submit(AdminState state) async {
    final schoolId = state.selectedSchoolId;
    if (schoolId == null || _teacherId == null || _studentIds.isEmpty) return;
    setState(() => _saving = true);
    final r = await _repo.createTeacherStudentLink(
      schoolId: schoolId,
      teacherId: _teacherId!,
      studentIds: _studentIds.toList(),
      sectionId: _sectionId,
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
            onPressed: (_teacherId != null && _studentIds.isNotEmpty && !_saving)
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
