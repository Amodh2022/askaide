part of '../public_pages.dart';

/// `/student/:userId` — shareable public achievement card.
class StudentPublicProfilePage extends StatelessWidget {
  const StudentPublicProfilePage({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PublicProfileCubit>(
      create: (_) => sl<PublicProfileCubit>()..load(userId),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final state = context.watch<PublicProfileCubit>().state;
    final d = state.data;
    return _PublicPage(
      maxWidth: 560,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: context.cardDecoration(),
        child: state.loading
            ? const Shimmer(
                child: Column(
                  children: [
                    SkeletonBox(width: 72, height: 72, radius: 36),
                    SizedBox(height: 16),
                    SkeletonBox(width: 180, height: 16),
                    SizedBox(height: 12),
                    SkeletonBox(width: 240, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 200, height: 12),
                  ],
                ),
              )
            : Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: c.accentLight,
                    child: Text(
                      (d?.name.isNotEmpty ?? false) ? d!.name[0].toUpperCase() : 'A',
                      style: AppTypography.statNumber(c.accent, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(d?.name ?? 'AskAide Student', style: AppTypography.h3(c.textPrimary)),
                  if ((d?.accountType ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: c.accentLight, borderRadius: AppRadii.pillR),
                      child: Text(d!.accountType.toUpperCase(), style: AppTypography.mono(c.accent, size: 9)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _PubStat(value: '${d?.questions ?? 0}', label: 'QUESTIONS'),
                      _PubStat(
                          value: (d == null || d.questions == 0) ? '—' : '${d.accuracy.round()}%',
                          label: 'ACCURACY'),
                      _PubStat(value: '🔥 ${d?.currentStreak ?? 0}', label: 'STREAK'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _PubStat(value: '🏆 ${d?.longestStreak ?? 0}', label: 'BEST STREAK'),
                      _PubStat(value: '${d?.subjects ?? 0}', label: 'SUBJECTS'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '/student/$userId'));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile link copied!')));
                    },
                    icon: Icon(LucideIcons.share2, size: 16, color: c.textPrimary),
                    label: Text('Share profile', style: AppTypography.button(c.textPrimary)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: c.border)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PubStat extends StatelessWidget {
  const _PubStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.statNumber(c.accent, size: 26)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.mono(c.textMuted, size: 9)),
        ],
      ),
    );
  }
}
