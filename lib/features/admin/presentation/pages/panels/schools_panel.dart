part of '../admin_dashboard_page.dart';

class _SchoolsPanel extends StatelessWidget {
  const _SchoolsPanel();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SchoolsPanelCubit>(
      create: (_) => sl<SchoolsPanelCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final panelCubit = context.read<SchoolsPanelCubit>();
    if (!panelCubit.formKey.currentState!.validate()) return;
    final editing = panelCubit.state.editing;
    final ok = await panelCubit.submit(context.read<AdminCubit>());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (editing != null ? 'School updated successfully' : 'School created successfully')
            : 'Operation failed')));
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AdminCubit>().state;
    final panelState = context.watch<SchoolsPanelCubit>().state;
    final panelCubit = context.read<SchoolsPanelCubit>();
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
            if (!panelState.formOpen)
              FilledButton.icon(
                onPressed: panelCubit.startCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add School'),
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              ),
          ],
        ),
        if (panelState.formOpen) ...[
          const SizedBox(height: 16),
          _formCard(context, c, panelCubit, panelState),
        ],
        const SizedBox(height: 16),
        if (state.status == ALoad.loading && state.schools.isEmpty)
          const SkeletonListLoader()
        else
          _grid(context, c, state.schools, panelCubit, panelState),
      ],
    );
  }

  Widget _formCard(BuildContext context, AskAideColors c, SchoolsPanelCubit panelCubit,
      SchoolsPanelState panelState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: panelCubit.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(panelState.editing != null ? 'Edit School' : 'Create New School',
                    style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                IconButton(
                    onPressed: panelCubit.cancel,
                    icon: Icon(Icons.close, size: 20, color: c.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth > 520 ? (box.maxWidth - 12) / 2 : box.maxWidth;
              final fields = <Widget>[
                AdminFormField(
                    label: 'School Name *',
                    controller: panelCubit.name,
                    hint: 'e.g. Greenwood High',
                    requiredField: true,
                    requiredMessage: 'School Name is required',
                    labelColor: c.textSecondary,
                    dense: false,
                    applyBodyStyle: false),
                AdminFormField(
                    label: 'School Code *',
                    controller: panelCubit.code,
                    hint: 'e.g. GW001',
                    requiredField: true,
                    requiredMessage: 'School Code is required',
                    labelColor: c.textSecondary,
                    dense: false,
                    applyBodyStyle: false),
                if (panelState.editing == null) ...[
                  AdminFormField(
                      label: 'Address *',
                      controller: panelCubit.address,
                      requiredField: true,
                      requiredMessage: 'Address is required',
                      labelColor: c.textSecondary,
                      dense: false,
                      applyBodyStyle: false),
                  AdminFormField(
                      label: 'Board *',
                      controller: panelCubit.board,
                      hint: 'e.g. CBSE',
                      requiredField: true,
                      requiredMessage: 'Board is required',
                      labelColor: c.textSecondary,
                      dense: false,
                      applyBodyStyle: false),
                  AdminFormField(
                      label: 'Phone',
                      controller: panelCubit.phone,
                      labelColor: c.textSecondary,
                      dense: false,
                      applyBodyStyle: false),
                  AdminFormField(
                      label: 'Email',
                      controller: panelCubit.email,
                      email: true,
                      emailMessage: 'Enter a valid email',
                      labelColor: c.textSecondary,
                      dense: false,
                      applyBodyStyle: false),
                  AdminFormField(
                      label: 'Website',
                      controller: panelCubit.website,
                      labelColor: c.textSecondary,
                      dense: false,
                      applyBodyStyle: false),
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
                TextButton(
                    onPressed: panelCubit.cancel,
                    child: Text('Cancel', style: AppTypography.button(c.textSecondary))),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: panelState.saving ? null : () => _submit(context),
                  icon: panelState.saving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, size: 18),
                  label: Text(panelState.editing != null ? 'Update School' : 'Create School'),
                  style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SchoolsPanelCubit panelCubit, AdminSchool s) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete school',
        message: 'Delete "${s.name}"? This cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok || !context.mounted) return;
    final success = await panelCubit.deleteSchool(context.read<AdminCubit>(), s.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'School deleted' : 'Could not delete school')));
  }

  Widget _grid(BuildContext context, AskAideColors c, List<AdminSchool> schools,
      SchoolsPanelCubit panelCubit, SchoolsPanelState panelState) {
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
            SizedBox(
                width: cols == 1 ? box.maxWidth : w,
                child: _card(context, c, panelCubit, panelState, s)),
        ],
      );
    });
  }

  Widget _card(BuildContext context, AskAideColors c, SchoolsPanelCubit panelCubit,
      SchoolsPanelState panelState, AdminSchool s) {
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
                onPressed: () => panelCubit.startEdit(s),
                icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
              ),
              IconButton(
                onPressed: panelState.deletingIds.contains(s.id)
                    ? null
                    : () => _confirmDelete(context, panelCubit, s),
                icon: panelState.deletingIds.contains(s.id)
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
