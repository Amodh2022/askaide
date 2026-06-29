part of '../admin_dashboard_page.dart';

class _UploadPanel extends StatefulWidget {
  const _UploadPanel({super.key});
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

  Future<void> _previewFile() async {
    if (_fileBytes == null) return;
    await Printing.sharePdf(
      bytes: _fileBytes!,
      filename: _fileName ?? 'chapter.pdf',
    );
  }

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
    final classes = context.select<AdminCubit, List<AdminRecord>>((c) => c.state.classes);

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
                              borderRadius: AppRadii.componentR),
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
                              borderRadius: AppRadii.componentR),
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
                      borderRadius: AppRadii.componentR,
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
                          icon: Icon(Icons.visibility_outlined, size: 16, color: c.accent),
                          onPressed: _previewFile,
                          splashRadius: 16,
                          tooltip: 'Preview PDF',
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
        _subjectId == null
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
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
      ],
    );
  }
}

