part of '../dashboard_page.dart';

/// Shimmer skeleton that mirrors the dashboard's actual card/box layout.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting area
          const SkeletonBox(width: 120, height: 11),
          const SizedBox(height: 8),
          const SkeletonBox(width: 220, height: 26),
          const SizedBox(height: 12),
          // Streak skeleton + share button row
          Row(
            children: [
              Container(
                width: 120,
                height: 46,
                decoration: BoxDecoration(
                  color: c.bgCard,
                  borderRadius: AppRadii.cardR,
                  border: Border.all(color: c.border),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.bgCard,
                  border: Border.all(color: c.border),
                  borderRadius: AppRadii.modalR,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick start CTA
          Container(
            width: 180,
            height: 44,
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: AppRadii.pillR,
            ),
          ),
          const SizedBox(height: 28),
          // Stats grid (3 across)
          LayoutBuilder(
            builder: (context, cons) {
              final w = (cons.maxWidth - 20) / 3;
              return Row(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: EdgeInsets.only(left: _ > 0 ? 10 : 0),
                    child: SizedBox(
                      width: w,
                      child: const SkeletonStatCard(),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Card grid (2 columns)
          LayoutBuilder(
            builder: (context, cons) {
              final w = (cons.maxWidth - 12) / 2;
              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: w, child: const SkeletonShellCard(showSubtitle: false)),
                      const SizedBox(width: 12),
                      SizedBox(width: w, child: const SkeletonShellCard(showSubtitle: false)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(width: w, child: const SkeletonShellCard(height: 180, child: SkeletonBox(height: 90))),
                      const SizedBox(width: 12),
                      SizedBox(width: w, child: const SkeletonShellCard(height: 180, child: SkeletonBox(height: 50))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(width: w, child: const SkeletonShellCard(height: 214, child: SkeletonBox(height: 130))),
                      const SizedBox(width: 12),
                      SizedBox(width: w, child: const SkeletonShellCard(height: 214, child: SkeletonBox(height: 50))),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          // Quick actions label
          const SkeletonBox(width: 100, height: 11),
          const SizedBox(height: 12),
          // Quick action cards
          ...List.generate(3, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SkeletonActionCard(),
          )),
          const SizedBox(height: 20),
          // Achievements + leaderboard grid (2 columns)
          LayoutBuilder(
            builder: (context, cons) {
              final w = (cons.maxWidth - 12) / 2;
              return Row(
                children: [
                  SizedBox(width: w, child: const SkeletonShellCard(showIcon: true, height: 260)),
                  const SizedBox(width: 12),
                  SizedBox(width: w, child: const SkeletonShellCard(showIcon: true, height: 260)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShellCard extends StatelessWidget {
  const _ShellCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTypography.bodySmall(c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({this.value, required this.label, this.animateTo, this.suffix = ''});
  final String? value;
  final String label;
  final int? animateTo; // when set, count up from 0
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = AppTypography.statNumber(c.textPrimary, size: 22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (animateTo != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: animateTo!.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
            )
          else
            Text(value ?? '—', style: style),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = accent ? Colors.white : c.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardR,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent ? c.accent : c.bgCard,
          border: Border.all(color: accent ? c.accent : c.borderSubtle),
          borderRadius: AppRadii.cardR,
          boxShadow: AppShadows.card(Theme.of(context).brightness),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h4(fg).copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall(accent ? Colors.white70 : c.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent ? Colors.white.withValues(alpha: 0.18) : c.accentLight,
                borderRadius: AppRadii.cardR,
              ),
              child: Icon(icon, size: 18, color: accent ? Colors.white : c.accent),
            ),
          ],
        ),
      ),
    );
  }
}
