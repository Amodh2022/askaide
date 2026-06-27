part of '../role_dashboard_pages.dart';

class _ParentView extends StatelessWidget {
  const _ParentView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final ov = state.overview;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    eyebrow: 'PARENT',
                    title: 'Family',
                    emphasis: 'oversight.',
                    subtitle: "Follow your child's practice, streaks, and mastery.",
                  ),
                  const SizedBox(height: 24),
                  if (state.status == PLoad.loading)
                    const SkeletonListLoader(padding: EdgeInsets.all(24))
                  else if (state.children.isEmpty)
                    Container(
                      width: double.infinity,
                      decoration: context.cardDecoration(),
                      child: const EmptyState(
                        icon: LucideIcons.users,
                        title: 'No linked children',
                        hint: 'Children linked to your account will appear here.',
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        _Overview(value: '${ov?.streakDays ?? 0}', label: 'STREAK'),
                        const SizedBox(width: 12),
                        _Overview(
                            value: ov == null ? '—' : '${(ov.overallMastery * 100).round()}%',
                            label: 'MASTERY'),
                        const SizedBox(width: 12),
                        _Overview(value: '${state.children.length}', label: 'CHILDREN'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Children', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                    const SizedBox(height: 8),
                    for (final child in state.children)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: context.cardDecoration(),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: c.accentLight,
                            child: Icon(LucideIcons.user, color: c.accent, size: 18),
                          ),
                          title: Text(child.name, style: AppTypography.labelLarge(c.textPrimary)),
                          subtitle: child.grade.isEmpty
                              ? null
                              : Text(child.grade, style: AppTypography.bodySmall(c.textMuted)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
