part of '../admin_dashboard_page.dart';

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    this.selectedId,
  });
  final String title;
  final List<AdminRecord> items;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminPickerSearchCubit>(
      create: (_) => sl<AdminPickerSearchCubit>(),
      child: Builder(builder: _buildSheet),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<AdminPickerSearchCubit>();
    final query = context.watch<AdminPickerSearchCubit>().state.trim().toLowerCase();
    final visible = query.isEmpty
        ? items
        : items
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
                  color: c.border, borderRadius: AppRadii.pillR),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(title,
                      style: AppTypography.h4(c.textPrimary)
                          .copyWith(fontSize: 18)),
                  const Spacer(),
                  if (items.isNotEmpty)
                    Text('${visible.length}',
                        style: AppTypography.mono(c.textMuted, size: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: true,
                onChanged: cubit.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search $title…',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: c.textMuted),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, size: 16, color: c.textMuted),
                          onPressed: () => cubit.setQuery(''),
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: AppRadii.componentR,
                      borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.componentR,
                      borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.componentR,
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
                        final sel = item.id == selectedId;
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
              borderRadius: AppRadii.componentR,
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
