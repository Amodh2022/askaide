import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/study_session.dart';
import '../bloc/session_bloc.dart';

/// The study-history rail: a "New session" action and a list of past sessions
/// (subject · chapter, time, score badge). Tapping one opens its review.
class StudyHistorySidebar extends StatelessWidget {
  const StudyHistorySidebar({super.key, this.onSelect});

  /// Called after a selection (used to close the mobile drawer).
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: AppRadii.modalR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LucideIcons.history, size: 18, color: c.textPrimary),
                const SizedBox(width: AppSpacing.xs),
                Text('Study History', style: AppTypography.labelLarge(c.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<SessionBloc>().add(const BackToConfigRequested());
                onSelect?.call();
              },
              icon: Icon(LucideIcons.plus, size: 16, color: c.accent),
              label: Text('New session', style: AppTypography.bodyMedium(c.accent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.border),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.cardR),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: BlocBuilder<SessionBloc, SessionState>(
              builder: (context, state) {
                if (state.history.isEmpty && state.historyStatus == LoadStatus.loading) {
                  return const _HistoryShimmer();
                }
                if (state.history.isEmpty) {
                  return const SizedBox.shrink();
                }
                final selectedId = state.reviewSession?.id;
                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xxs),
                  itemBuilder: (context, i) => _HistoryRow(
                    session: state.history[i],
                    isSelected: state.history[i].id == selectedId,
                    onTap: () {
                      context
                          .read<SessionBloc>()
                          .add(SessionReviewOpened(state.history[i].id));
                      onSelect?.call();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryShimmer extends StatelessWidget {
  const _HistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: List.generate(
          5,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 12),
                      SizedBox(height: 6),
                      SkeletonBox(width: 80, height: 10),
                    ],
                  ),
                ),
                SkeletonBox(width: 40, height: 18, radius: 9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.session, required this.onTap, this.isSelected = false});
  final StudySession session;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pct = (session.accuracy * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardR,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? c.accentLight : Colors.transparent,
          borderRadius: AppRadii.cardR,
          border: isSelected
              ? Border.all(color: c.accent.withValues(alpha: 0.35))
              : null,
        ),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge(c.textPrimary).copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(session.chapterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(c.textMuted).copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            if (session.answeredCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: AppRadii.pillR,
                ),
                child: Text('$pct%', style: AppTypography.mono(c.accent, size: 10)),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
