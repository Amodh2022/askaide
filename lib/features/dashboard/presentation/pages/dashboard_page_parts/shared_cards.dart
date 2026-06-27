part of '../dashboard_page.dart';

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
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent ? c.accent : c.bgCard,
          border: Border.all(color: accent ? c.accent : c.borderSubtle),
          borderRadius: BorderRadius.circular(4),
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
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 18, color: accent ? Colors.white : c.accent),
            ),
          ],
        ),
      ),
    );
  }
}
