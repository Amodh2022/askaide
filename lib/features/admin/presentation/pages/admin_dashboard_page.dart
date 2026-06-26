import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

// ── Bottom-sheet picker shared by all admin selectors ────────────────────────

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    this.selectedId,
  });
  final String title;
  final List<AdminRecord> items;
  final String? selectedId;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final query = _searchCtl.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.items
        : widget.items
            .where((it) =>
                it.name.toLowerCase().contains(query) ||
                it.subtitle.toLowerCase().contains(query))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: c.border, borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(widget.title,
                      style: AppTypography.h4(c.textPrimary)
                          .copyWith(fontSize: 18)),
                  const Spacer(),
                  if (widget.items.isNotEmpty)
                    Text('${visible.length}',
                        style: AppTypography.mono(c.textMuted, size: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtl,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title}…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: c.textMuted),
                  suffixIcon: _searchCtl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, size: 16, color: c.textMuted),
                          onPressed: () => setState(() => _searchCtl.clear()),
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.accent, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: c.border),
            Flexible(
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 32, color: c.textMuted),
                          const SizedBox(height: 8),
                          Text('No results for "$query"',
                              style: AppTypography.bodySmall(c.textMuted),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: c.borderSubtle),
                      itemBuilder: (ctx2, i) {
                        final item = visible[i];
                        final sel = item.id == widget.selectedId;
                        return ListTile(
                          title: Text(item.name,
                              style: AppTypography.bodyMedium(
                                  sel ? c.accent : c.textPrimary)),
                          subtitle: item.subtitle.isNotEmpty
                              ? Text(item.subtitle,
                                  style: AppTypography.bodySmall(c.textMuted))
                              : null,
                          trailing: sel
                              ? Icon(Icons.check_circle,
                                  color: c.accent, size: 20)
                              : null,
                          onTap: () => Navigator.pop(ctx2, item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showAdminPicker(
  BuildContext context, {
  required String title,
  required List<AdminRecord> items,
  String? selectedId,
}) async {
  final c = context.colors;
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.bgCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (bsCtx) => _PickerSheet(
      title: title,
      items: items,
      selectedId: selectedId,
    ),
  );
  return result;
}

// ── _PickerField ──────────────────────────────────────────────────────────────

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });
  final String label;
  final String hint;
  final List<AdminRecord> items;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected =
        selectedId != null ? items.where((e) => e.id == selectedId).firstOrNull : null;
    final hasValue = selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTypography.mono(c.textMuted, size: 10)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: items.isEmpty
              ? null
              : () async {
                  final v = await _showAdminPicker(
                    context,
                    title: label,
                    items: items,
                    selectedId: selectedId,
                  );
                  if (v != null) onChanged(v);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: c.bgCard,
              border: Border.all(
                  color: hasValue ? c.accent : c.border,
                  width: hasValue ? 1.5 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? selected.name : hint,
                    style: AppTypography.bodyMedium(
                        hasValue ? c.textPrimary : c.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  items.isEmpty
                      ? Icons.hourglass_empty
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: hasValue ? c.accent : c.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
  final _tabScrollCtl = ScrollController();
  final _tabKeys = List.generate(10, (_) => GlobalKey());

  /// Tabs that scope by the global header school selector. Schools/Teachers
  /// carry their own picker; the rest read the global selection.
  bool get _usesGlobalSchool => false;

  @override
  void dispose() {
    _tabScrollCtl.dispose();
    super.dispose();
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _PickerField(
                      label: 'School',
                      hint: 'Select school…',
                      items: state.schools
                          .map((s) => AdminRecord(id: s.id, name: s.name))
                          .toList(),
                      selectedId: state.selectedSchoolId,
                      onChanged: (v) => context.read<AdminCubit>().selectSchool(v),
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              controller: _tabScrollCtl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = i == _selected;
                return Center(
                  key: _tabKeys[i],
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = i);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final ctx = _tabKeys[i].currentContext;
                        if (ctx != null) {
                          Scrollable.ensureVisible(ctx,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              alignmentPolicy:
                                  ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
                        }
                      });
                    },
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
        return const _StudentsPanel();
      case 'Sections':
        return const _SectionsPanel();
      case 'Mappings':
        return const _MappingsPanel();
      case 'Upload':
        return const _UploadPanel();
      case 'Chapters':
        return const _ChaptersPanel();
      case 'Topics':
        return const _TopicsPanel();
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

}

/// One editable person row used in the Teachers and Students create forms.
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

class _UploadPanel extends StatefulWidget {
  const _UploadPanel();
  @override
  State<_UploadPanel> createState() => _UploadPanelState();
}

class _UploadPanelState extends State<_UploadPanel> {
  final _repo = sl<AdminRepository>();

  String? _classId;
  String? _subjectId;
  List<AdminRecord> _subjects = const [];
  List<AdminRecord> _chapters = const [];

  final _nameCtl = TextEditingController();
  final _orderCtl = TextEditingController();

  Uint8List? _fileBytes;
  String? _fileName;
  bool _uploading = false;
  bool _loadingChapters = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _orderCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
      _chapters = const [];
    });
    final r = await _repo.subjects(classId);
    if (!mounted) return;
    setState(() => _subjects = r.getOrElse(() => const []));
  }

  Future<void> _loadChapters(String subjectId) async {
    setState(() {
      _subjectId = subjectId;
      _loadingChapters = true;
      _chapters = const [];
    });
    final r = await _repo.chapters(_classId!, subjectId);
    if (!mounted) return;
    setState(() {
      _loadingChapters = false;
      _chapters = r.getOrElse(() => const []);
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _fileBytes = file.bytes;
      _fileName = file.name;
    });
  }

  void _clearFile() => setState(() {
        _fileBytes = null;
        _fileName = null;
      });

  Future<void> _deleteChapterItem(String id) async {
    final sid = _subjectId!;
    final r = await _repo.deleteChapters(_classId!, sid, [id]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.isRight() ? 'Deleted' : 'Could not delete')));
    if (r.isRight()) _loadChapters(sid);
  }

  Future<void> _upload() async {
    final classId = _classId;
    final subjectId = _subjectId;
    final bytes = _fileBytes;
    final name = _nameCtl.text.trim();
    final order = int.tryParse(_orderCtl.text.trim()) ?? 0;
    final filename = _fileName ?? 'chapter.pdf';

    if (classId == null || subjectId == null || bytes == null || name.isEmpty) return;

    setState(() => _uploading = true);
    final r = await _repo.createChapterWithPdf(
      classId: classId,
      subjectId: subjectId,
      chapterName: name,
      order: order,
      bytes: bytes,
      filename: filename,
    );
    if (!mounted) return;
    setState(() => _uploading = false);

    if (r.isRight()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chapter uploaded')));
      _nameCtl.clear();
      _orderCtl.clear();
      _clearFile();
      _loadChapters(subjectId);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final classes = context.watch<AdminCubit>().state.classes;

    final canUpload = _classId != null &&
        _subjectId != null &&
        _fileBytes != null &&
        _nameCtl.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Class / Subject selectors ──────────────────────────────────────
        _ClassSubjectSelector(
          classes: classes,
          classId: _classId,
          subjects: _subjects,
          subjectId: _subjectId,
          onClass: _loadSubjects,
          onSubject: _loadChapters,
        ),

        if (_subjectId != null) ...[
          Divider(height: 1, color: c.border),

          // ── Upload form ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chapter name + Order row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameCtl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Chapter name',
                          labelStyle: TextStyle(color: c.textMuted),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _orderCtl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Order',
                          labelStyle: TextStyle(color: c.textMuted),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // PDF pick area
                if (_fileBytes == null)
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Pick PDF'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: BorderSide(color: c.border),
                      foregroundColor: c.textSecondary,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.06),
                      border: Border.all(color: c.accent.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined,
                            color: c.accent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_fileName ?? '',
                                  style: AppTypography.bodySmall(c.textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  '${(_fileBytes!.lengthInBytes / 1024).round()} KB',
                                  style:
                                      AppTypography.mono(c.textMuted, size: 10)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 16, color: c.textMuted),
                          onPressed: _clearFile,
                          splashRadius: 16,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Upload button
                FilledButton.icon(
                  onPressed: (canUpload && !_uploading) ? _upload : null,
                  icon: _uploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: Text(_uploading ? 'Uploading…' : 'Upload chapter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
        ],

        // ── Existing chapters list ─────────────────────────────────────────
        Expanded(
          child: _subjectId == null
              ? const EmptyState(
                  icon: Icons.upload_file_outlined,
                  title: 'Pick a class & subject',
                  hint: 'Then fill the form above to upload a PDF chapter.',
                )
              : _loadingChapters
                  ? const SkeletonListLoader()
                  : _chapters.isEmpty
                      ? const EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'No chapters yet',
                          hint: 'Upload the first chapter above.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _chapters.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: c.borderSubtle),
                          itemBuilder: (context, i) => ListTile(
                            leading: Icon(Icons.picture_as_pdf_outlined,
                                color: c.accent, size: 20),
                            title: Text(_chapters[i].name,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTypography.bodyMedium(c.textPrimary)),
                            subtitle: _chapters[i].subtitle.isEmpty
                                ? null
                                : Text(_chapters[i].subtitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall(c.textMuted)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: c.danger),
                            onPressed: () => _deleteChapterItem(_chapters[i].id),
                            ),
                          ),
                        ),
        ),
      ],
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
          onClass: _loadSubjects,
          onSubject: _loadItems,
        ),
        if (widget.mode != _CurriculumMode.topics && _subjectId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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

// ─────────────────────────────────────────────────────────────────────────────
// Chapters tab — card-based management matching Schools / Teachers quality.
// ─────────────────────────────────────────────────────────────────────────────

class _ChaptersPanel extends StatefulWidget {
  const _ChaptersPanel();
  @override
  State<_ChaptersPanel> createState() => _ChaptersPanelState();
}

class _ChaptersPanelState extends State<_ChaptersPanel> {
  final _repo = sl<AdminRepository>();
  String? _classId;
  String? _subjectId;
  List<AdminRecord> _subjects = const [];
  List<AdminRecord> _chapters = const [];
  final Set<String> _selected = {};
  bool _loading = false;
  bool _formOpen = false;
  bool _creating = false;
  String? _deletingId;
  bool _bulkDeleting = false;
  String _search = '';

  final _nameCtl = TextEditingController();
  final _orderCtl = TextEditingController();
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _nameCtl.dispose();
    _orderCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
      _chapters = const [];
      _selected.clear();
      _search = '';
      _searchCtl.clear();
    });
    final r = await _repo.subjects(classId);
    if (!mounted) return;
    setState(() => _subjects = r.getOrElse(() => const []));
  }

  Future<void> _loadChapters(String subjectId) async {
    setState(() {
      _subjectId = subjectId;
      _loading = true;
      _chapters = const [];
      _selected.clear();
      _search = '';
      _searchCtl.clear();
    });
    final r = await _repo.chapters(_classId!, subjectId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _chapters = r.getOrElse(() => const []);
    });
  }

  Future<void> _create() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) { _snack('Chapter name is required'); return; }
    setState(() => _creating = true);
    final r = await _repo.createChapter(
        _classId!, _subjectId!, name, int.tryParse(_orderCtl.text.trim()) ?? 0);
    if (!mounted) return;
    setState(() => _creating = false);
    _snack(r.isRight() ? 'Chapter created' : 'Could not create chapter');
    if (r.isRight()) {
      _nameCtl.clear();
      _orderCtl.clear();
      setState(() => _formOpen = false);
      _loadChapters(_subjectId!);
    }
  }

  Future<void> _delete(String id) async {
    setState(() => _deletingId = id);
    final r = await _repo.deleteChapters(_classId!, _subjectId!, [id]);
    if (!mounted) return;
    setState(() => _deletingId = null);
    _snack(r.isRight() ? 'Deleted' : 'Could not delete');
    if (r.isRight()) _loadChapters(_subjectId!);
  }

  void _toggleSelectAll(List<AdminRecord> visible) {
    setState(() {
      final visibleIds = visible.map((e) => e.id).toSet();
      if (visibleIds.every(_selected.contains)) {
        _selected.removeAll(visibleIds);
      } else {
        _selected.addAll(visibleIds);
      }
    });
  }

  Future<void> _bulkDelete() async {
    final n = _selected.length;
    final ok = await showConfirmDialog(context,
        title: 'Delete chapters',
        message: 'Delete $n chapter(s)? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok || !mounted) return;
    setState(() => _bulkDeleting = true);
    final r = await _repo.deleteChapters(_classId!, _subjectId!, _selected.toList());
    if (!mounted) return;
    setState(() => _bulkDeleting = false);
    _snack(r.isRight() ? 'Deleted $n chapter(s)' : 'Could not delete');
    if (r.isRight()) {
      setState(() => _selected.clear());
      _loadChapters(_subjectId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final classes = context.watch<AdminCubit>().state.classes;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text('Chapter Management',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
            ),
            if (_subjectId != null && !_formOpen)
              FilledButton.icon(
                onPressed: () => setState(() => _formOpen = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Chapter'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _selectorCard(context, c, classes),
        if (_formOpen) ...[
          const SizedBox(height: 16),
          _formCard(c),
        ],
        if (_subjectId != null) ...[
          const SizedBox(height: 16),
          _chaptersCard(c),
        ],
      ],
    );
  }

  Widget _selectorCard(BuildContext context, AskAideColors c, List<AdminRecord> classes) {
    final mobile = context.isMobile;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PickerField(
                  label: 'Class',
                  hint: 'Select class…',
                  items: classes,
                  selectedId: _classId,
                  onChanged: _loadSubjects,
                ),
                const SizedBox(height: 12),
                _PickerField(
                  label: 'Subject',
                  hint: 'Select subject…',
                  items: _subjects,
                  selectedId: _subjectId,
                  onChanged: _loadChapters,
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
                    selectedId: _classId,
                    onChanged: _loadSubjects,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Subject',
                    hint: 'Select subject…',
                    items: _subjects,
                    selectedId: _subjectId,
                    onChanged: _loadChapters,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _formCard(AskAideColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Create New Chapter',
                  style:
                      AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
              IconButton(
                onPressed: () {
                  setState(() => _formOpen = false);
                  _nameCtl.clear();
                  _orderCtl.clear();
                },
                icon: Icon(Icons.close, size: 20, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth > 500;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: wide ? (box.maxWidth - 12) * 0.72 : box.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CHAPTER NAME *',
                          style:
                              AppTypography.mono(c.textSecondary, size: 10)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameCtl,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            hintText: 'e.g. Introduction to Algebra'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: wide
                      ? (box.maxWidth - 12) * 0.28 - 12
                      : box.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ORDER',
                          style:
                              AppTypography.mono(c.textSecondary, size: 10)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _orderCtl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(hintText: '1'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _formOpen = false);
                  _nameCtl.clear();
                  _orderCtl.clear();
                },
                child: Text('Cancel',
                    style: AppTypography.button(c.textSecondary)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed:
                    (_creating || _nameCtl.text.trim().isEmpty) ? null : _create,
                icon: _creating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: const Text('Create Chapter'),
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chaptersCard(AskAideColors c) {
    final query = _search.trim().toLowerCase();
    final visible = query.isEmpty
        ? _chapters
        : _chapters
            .where((ch) => ch.name.toLowerCase().contains(query))
            .toList();

    final visibleIds = visible.map((e) => e.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selected.contains);
    final someVisibleSelected =
        visibleIds.any(_selected.contains) && !allVisibleSelected;

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header row ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('Chapters',
                    style: AppTypography.h4(c.textPrimary)
                        .copyWith(fontSize: 16)),
                const SizedBox(width: 8),
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      query.isEmpty
                          ? '${_chapters.length}'
                          : '${visible.length} of ${_chapters.length}',
                      style: AppTypography.mono(c.accent, size: 11),
                    ),
                  ),
                const Spacer(),
                if (!_loading && _chapters.isNotEmpty) ...[
                  Checkbox(
                    tristate: true,
                    value: someVisibleSelected ? null : allVisibleSelected,
                    activeColor: c.accent,
                    onChanged: (_) => _toggleSelectAll(visible),
                  ),
                  Text('All',
                      style: AppTypography.bodySmall(c.textSecondary)),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _loadChapters(_subjectId!),
                    icon: Icon(Icons.refresh,
                        size: 18, color: c.textMuted),
                    tooltip: 'Refresh',
                  ),
                ],
              ],
            ),
          ),

          // ── Bulk-action bar (only when items are selected) ───────────────
          if (_selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: c.danger.withValues(alpha: 0.06),
                border: Border(
                  top: BorderSide(color: c.danger.withValues(alpha: 0.2)),
                  bottom: BorderSide(color: c.danger.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_box_outlined,
                      size: 16, color: c.danger),
                  const SizedBox(width: 8),
                  Text('${_selected.length} selected',
                      style: AppTypography.bodySmall(c.danger)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _selected.clear()),
                    icon: Icon(Icons.close, size: 14, color: c.textMuted),
                    label: Text('Clear',
                        style: AppTypography.bodySmall(c.textMuted)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8)),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: _bulkDeleting ? null : _bulkDelete,
                    icon: _bulkDeleting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.delete_outline, size: 16),
                    label: Text(
                      _bulkDeleting
                          ? 'Deleting…'
                          : 'Delete (${_selected.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

          // ── Search bar ───────────────────────────────────────────────────
          if (!_loading && _chapters.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search chapters…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: c.textMuted),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: c.textMuted),
                          onPressed: () => setState(
                              () { _search = ''; _searchCtl.clear(); }),
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: c.accent, width: 1.5)),
                ),
              ),
            ),

          Divider(height: 1, color: c.border),

          // ── Body ─────────────────────────────────────────────────────────
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonListLoader())
          else if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: query.isNotEmpty
                    ? 'No chapters match "$query"'
                    : 'No chapters yet',
                hint: query.isNotEmpty
                    ? 'Try a different search term.'
                    : 'Use "Add Chapter" above to create the first one.',
              ),
            )
          else
            ...List.generate(visible.length, (i) {
              final ch = visible[i];
              final isDeleting = _deletingId == ch.id;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Checkbox(
                      value: _selected.contains(ch.id),
                      activeColor: c.accent,
                      onChanged: (v) => setState(() => v == true
                          ? _selected.add(ch.id)
                          : _selected.remove(ch.id)),
                    ),
                    title: Text(ch.name,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.bodyMedium(c.textPrimary)),
                    subtitle: ch.subtitle.isNotEmpty
                        ? Text(ch.subtitle,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTypography.bodySmall(c.textMuted))
                        : null,
                    trailing: isDeleting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: c.danger),
                            onPressed: () => _delete(ch.id),
                            tooltip: 'Delete chapter',
                          ),
                  ),
                  if (i < visible.length - 1)
                    Divider(height: 1, color: c.borderSubtle),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topics tab — read-only browse of topics for a class + subject.
// Topics are auto-generated by AI ingestion; admin can only view them.
// ─────────────────────────────────────────────────────────────────────────────

class _TopicsPanel extends StatefulWidget {
  const _TopicsPanel();
  @override
  State<_TopicsPanel> createState() => _TopicsPanelState();
}

class _TopicsPanelState extends State<_TopicsPanel> {
  final _repo = sl<AdminRepository>();
  String? _classId;
  String? _subjectId;
  List<AdminRecord> _subjects = const [];
  List<AdminRecord> _topics = const [];
  bool _loading = false;
  String _search = '';

  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _classId = classId;
      _subjectId = null;
      _subjects = const [];
      _topics = const [];
      _search = '';
      _searchCtl.clear();
    });
    final r = await _repo.subjects(classId);
    if (!mounted) return;
    setState(() => _subjects = r.getOrElse(() => const []));
  }

  Future<void> _loadTopics(String subjectId) async {
    setState(() {
      _subjectId = subjectId;
      _loading = true;
      _topics = const [];
      _search = '';
      _searchCtl.clear();
    });
    final r = await _repo.topics(_classId!, subjectId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _topics = r.getOrElse(() => const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final classes = context.watch<AdminCubit>().state.classes;

    final query = _search.trim().toLowerCase();
    final visible = query.isEmpty
        ? _topics
        : _topics.where((t) => t.name.toLowerCase().contains(query)).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text('Topic Browser',
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
            ),
            if (_subjectId != null)
              IconButton(
                onPressed: () => _loadTopics(_subjectId!),
                icon: Icon(Icons.refresh, size: 20, color: c.textMuted),
                tooltip: 'Refresh',
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Class + Subject selector card ────────────────────────────────────
        _selectorCard(context, c, classes),
        const SizedBox(height: 16),

        // ── Topics card ──────────────────────────────────────────────────────
        if (_subjectId != null) _topicsCard(c, visible),
      ],
    );
  }

  Widget _selectorCard(BuildContext context, AskAideColors c, List<AdminRecord> classes) {
    final mobile = context.isMobile;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PickerField(
                  label: 'Class',
                  hint: 'Select class…',
                  items: classes,
                  selectedId: _classId,
                  onChanged: _loadSubjects,
                ),
                const SizedBox(height: 12),
                _PickerField(
                  label: 'Subject',
                  hint: 'Select subject…',
                  items: _subjects,
                  selectedId: _subjectId,
                  onChanged: _loadTopics,
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
                    selectedId: _classId,
                    onChanged: _loadSubjects,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Subject',
                    hint: 'Select subject…',
                    items: _subjects,
                    selectedId: _subjectId,
                    onChanged: _loadTopics,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _topicsCard(AskAideColors c, List<AdminRecord> visible) {
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('Topics',
                    style: AppTypography.h4(c.textPrimary)
                        .copyWith(fontSize: 16)),
                const SizedBox(width: 8),
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _search.isEmpty
                          ? '${_topics.length}'
                          : '${visible.length} of ${_topics.length}',
                      style: AppTypography.mono(c.accent, size: 11),
                    ),
                  ),
              ],
            ),
          ),

          // ── Search bar ───────────────────────────────────────────────────
          if (!_loading && _topics.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search topics…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: c.textMuted),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: c.textMuted),
                          onPressed: () =>
                              setState(() { _search = ''; _searchCtl.clear(); }),
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: c.accent, width: 1.5)),
                ),
              ),
            ),
          Divider(height: 1, color: c.border),

          // ── Body ────────────────────────────────────────────────────────
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonListLoader())
          else if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.library_books_outlined,
                title: _search.isNotEmpty
                    ? 'No topics match "$_search"'
                    : 'No topics yet',
                hint: _search.isNotEmpty
                    ? 'Try a different search term.'
                    : 'Topics are generated automatically when a chapter PDF is processed.',
              ),
            )
          else
            ...List.generate(visible.length, (i) {
              final topic = visible[i];
              // Index in the full list (for stable numbering regardless of search)
              final globalIndex = _topics.indexOf(topic);
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${globalIndex + 1}',
                        style: AppTypography.mono(c.accent, size: 11),
                      ),
                    ),
                    title: Text(topic.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium(c.textPrimary)),
                  ),
                  if (i < visible.length - 1)
                    Divider(height: 1, color: c.borderSubtle),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(20),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PickerField(
            label: 'School',
            hint: 'Select school…',
            items: state.schools
                .map((s) => AdminRecord(
                    id: s.id,
                    name: s.code.isEmpty ? s.name : '${s.name} (${s.code})'))
                .toList(),
            selectedId: state.selectedSchoolId,
            onChanged: (v) => context.read<AdminCubit>().selectSchool(v),
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
      padding: const EdgeInsets.all(20),
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
                : Text(t.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(c.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: editing
                ? _inlineField(c, _editEmail)
                : Text(t.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(c.textSecondary)),
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
                  Text(t.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium(c.textPrimary)),
                  Text(t.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(c.textMuted)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Students tab
// ─────────────────────────────────────────────────────────────────────────────

class _StudentsPanel extends StatefulWidget {
  const _StudentsPanel();
  @override
  State<_StudentsPanel> createState() => _StudentsPanelState();
}

class _StudentsPanelState extends State<_StudentsPanel> {
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
    final ok = await context.read<AdminCubit>().createStudents(payload);
    if (!mounted) return;
    setState(() => _creating = false);
    _snack(ok ? 'Successfully created $n student${n != 1 ? 's' : ''}' : 'Failed to create students');
    if (ok) {
      setState(() {
        for (final r in _rows) {
          r.dispose();
        }
        _rows = [_PersonRow()];
      });
    }
  }

  void _openEdit(AdminRecord s) => setState(() {
        _editingId = s.id;
        _editName.text = s.name;
        _editEmail.text = s.subtitle;
      });

  Future<void> _saveEdit(String id) async {
    if (_editName.text.trim().isEmpty || _editEmail.text.trim().isEmpty) {
      _snack('Name and email are required');
      return;
    }
    setState(() => _editSaving = true);
    final ok = await context.read<AdminCubit>().updateStudent(id, {
      'name': _editName.text.trim(),
      'email': _editEmail.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _editSaving = false;
      if (ok) _editingId = null;
    });
    _snack(ok ? 'Student updated' : 'Failed to update student');
  }

  Future<void> _delete(String id) async {
    setState(() => _deletingId = id);
    await context.read<AdminCubit>().deleteStudent(id);
    if (mounted) setState(() => _deletingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    final hasSchool = state.selectedSchoolId != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Student Management', style: AppTypography.h3(c.textPrimary).copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        _createCard(c, state, hasSchool),
        if (hasSchool) ...[
          const SizedBox(height: 16),
          _listCard(c, state.students),
        ],
      ],
    );
  }

  Widget _createCard(AskAideColors c, AdminState state, bool hasSchool) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PickerField(
            label: 'School',
            hint: 'Select school…',
            items: state.schools
                .map((s) => AdminRecord(
                    id: s.id,
                    name: s.code.isEmpty ? s.name : '${s.name} (${s.code})'))
                .toList(),
            selectedId: state.selectedSchoolId,
            onChanged: (v) => context.read<AdminCubit>().selectSchool(v),
          ),
          if (hasSchool) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add New Students', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
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
                label: Text('Create ${_rows.length} Student${_rows.length != 1 ? 's' : ''}'),
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
        hint: 'Jane Doe',
        requiredField: true,
        trailing: IconButton(
          tooltip: 'Auto-generate email & password',
          onPressed: () => _generate(i),
          icon: Icon(Icons.auto_fix_high, size: 18, color: c.accent),
        ));
    final emailField = _tf(c, 'Email *', r.email, hint: 'jane@school.com', requiredField: true, email: true);
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

  Widget _listCard(AskAideColors c, List<AdminRecord> students) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('Students', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
            const SizedBox(width: 8),
            Text('(${students.length})', style: AppTypography.bodySmall(c.textMuted)),
          ]),
          const SizedBox(height: 12),
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: Icons.school_outlined,
                title: 'No Students Found',
                hint: 'Add students with the form above.',
              ),
            )
          else if (context.isMobile)
            Column(children: [for (final s in students) _studentCardMobile(c, s)])
          else ...[
            Row(children: [
              Expanded(flex: 4, child: Text('NAME', style: AppTypography.mono(c.textMuted, size: 10))),
              Expanded(flex: 5, child: Text('EMAIL', style: AppTypography.mono(c.textMuted, size: 10))),
              SizedBox(width: 96, child: Text('ACTIONS', textAlign: TextAlign.right, style: AppTypography.mono(c.textMuted, size: 10))),
            ]),
            Divider(height: 12, color: c.border),
            for (final s in students) _studentRowDesktop(c, s),
          ],
        ],
      ),
    );
  }

  Widget _studentRowDesktop(AskAideColors c, AdminRecord s) {
    final editing = _editingId == s.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: editing
                ? _inlineField(c, _editName)
                : Text(s.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(c.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: editing
                ? _inlineField(c, _editEmail)
                : Text(s.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(c.textSecondary)),
          ),
          SizedBox(width: 96, child: _actions(c, s, editing)),
        ],
      ),
    );
  }

  Widget _studentCardMobile(AskAideColors c, AdminRecord s) {
    final editing = _editingId == s.id;
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
              Align(alignment: Alignment.centerRight, child: _actions(c, s, true)),
            ])
          : Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium(c.textPrimary)),
                  Text(s.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(c.textMuted)),
                ]),
              ),
              _actions(c, s, false),
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

  Widget _actions(AskAideColors c, AdminRecord s, bool editing) {
    if (editing) {
      return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
        IconButton(
          onPressed: _editSaving ? null : () => _saveEdit(s.id),
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
        onPressed: () => _openEdit(s),
        icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
      ),
      IconButton(
        onPressed: _deletingId == s.id ? null : () => _delete(s.id),
        icon: _deletingId == s.id
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
  AdminSchool? _editing;
  bool _saving = false;
  final Set<String> _deletingIds = {};

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

  void _startEdit(AdminSchool s) => setState(() {
        _editing = s;
        _isCreating = false;
        _resetFields();
        _name.text = s.name;
        _code.text = s.code;
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
      padding: const EdgeInsets.all(20),
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
      padding: const EdgeInsets.all(20),
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

  Future<void> _confirmDelete(AdminSchool s) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete school',
        message: 'Delete "${s.name}"? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok || !mounted) return;
    setState(() => _deletingIds.add(s.id));
    final success = await context.read<AdminCubit>().deleteSchool(s.id);
    if (!mounted) return;
    setState(() => _deletingIds.remove(s.id));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'School deleted' : 'Could not delete school')));
  }

  Widget _grid(AskAideColors c, List<AdminSchool> schools) {
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

  Widget _card(AskAideColors c, AdminSchool s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text('Code: ${s.code}', style: AppTypography.bodySmall(c.textMuted)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _startEdit(s),
                icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
              ),
              IconButton(
                onPressed: _deletingIds.contains(s.id) ? null : () => _confirmDelete(s),
                icon: _deletingIds.contains(s.id)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.delete_outline, size: 18, color: c.danger),
              ),
            ],
          ),
          if (s.address.isNotEmpty || s.board.isNotEmpty || s.phone.isNotEmpty ||
              s.email.isNotEmpty || s.website.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: c.border),
            const SizedBox(height: 8),
            if (s.address.isNotEmpty) _detail(c, Icons.location_on_outlined, s.address),
            if (s.board.isNotEmpty) _detail(c, Icons.school_outlined, s.board),
            if (s.phone.isNotEmpty) _detail(c, Icons.phone_outlined, s.phone),
            if (s.email.isNotEmpty) _detail(c, Icons.email_outlined, s.email),
            if (s.website.isNotEmpty) _detail(c, Icons.language_outlined, s.website),
          ],
        ],
      ),
    );
  }

  Widget _detail(AskAideColors c, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(c.textMuted)),
            ),
          ],
        ),
      );
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
class _MappingsPanel extends StatefulWidget {
  const _MappingsPanel();
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
                    borderRadius: BorderRadius.circular(99),
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
                borderRadius: BorderRadius.circular(8),
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
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
