part of '../admin_dashboard_page.dart';

class _UploadPanel extends StatelessWidget {
  const _UploadPanel();

  Future<void> _deleteChapterItem(BuildContext context, String id) async {
    final cubit = context.read<UploadChapterCubit>();
    final ok = await cubit.deleteChapter(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Deleted' : 'Could not delete')));
  }

  Future<void> _upload(BuildContext context) async {
    final cubit = context.read<UploadChapterCubit>();
    final ok = await cubit.upload();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Chapter uploaded' : 'Upload failed')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UploadChapterCubit>(
      create: (_) => sl<UploadChapterCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<UploadChapterCubit>();
    final classes = context.watch<AdminCubit>().state.classes;
    final state = context.watch<UploadChapterCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Class / Subject selectors ──────────────────────────────────────
        _ClassSubjectSelector(
          classes: classes,
          classId: state.classId,
          subjects: state.subjects,
          subjectId: state.subjectId,
          onClass: cubit.selectClass,
          onSubject: cubit.selectSubject,
        ),

        if (state.subjectId != null) ...[
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
                        controller: cubit.name,
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
                        controller: cubit.order,
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
                if (state.fileBytes == null)
                  OutlinedButton.icon(
                    onPressed: cubit.pickFile,
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
                              Text(state.fileName ?? '',
                                  style: AppTypography.bodySmall(c.textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  '${(state.fileBytes!.lengthInBytes / 1024).round()} KB',
                                  style:
                                      AppTypography.mono(c.textMuted, size: 10)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 16, color: c.textMuted),
                          onPressed: cubit.clearFile,
                          splashRadius: 16,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Upload button — AnimatedBuilder watches the name controller
                // so "canUpload" stays live as the user types (no setState).
                AnimatedBuilder(
                  animation: cubit.name,
                  builder: (context, _) {
                    final canUpload = state.classId != null &&
                        state.subjectId != null &&
                        state.fileBytes != null &&
                        cubit.name.text.trim().isNotEmpty;
                    return FilledButton.icon(
                      onPressed: (canUpload && !state.uploading)
                          ? () => _upload(context)
                          : null,
                      icon: state.uploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: Text(state.uploading ? 'Uploading…' : 'Upload chapter'),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
        ],

        // ── Existing chapters list ─────────────────────────────────────────
        Expanded(
          child: state.subjectId == null
              ? const EmptyState(
                  icon: Icons.upload_file_outlined,
                  title: 'Pick a class & subject',
                  hint: 'Then fill the form above to upload a PDF chapter.',
                )
              : state.loadingChapters
                  ? const SkeletonListLoader()
                  : state.chapters.isEmpty
                      ? const EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'No chapters yet',
                          hint: 'Upload the first chapter above.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: state.chapters.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: c.borderSubtle),
                          itemBuilder: (context, i) => ListTile(
                            leading: Icon(Icons.picture_as_pdf_outlined,
                                color: c.accent, size: 20),
                            title: Text(state.chapters[i].name,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTypography.bodyMedium(c.textPrimary)),
                            subtitle: state.chapters[i].subtitle.isEmpty
                                ? null
                                : Text(state.chapters[i].subtitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall(c.textMuted)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: c.danger),
                            onPressed: () => _deleteChapterItem(context, state.chapters[i].id),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

