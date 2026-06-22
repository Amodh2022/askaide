import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';

/// `/` — the marketing landing page. Hero ("Do the work, not the watching."),
/// a live-stats row, primary CTAs, a "why practice beats watching" feature grid,
/// and a dark CTA band. Mirrors the frontend LandingPage's key sections.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          _Hero(),
          _TrustStrip(),
          _Features(),
          _CtaBand(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('— A PRACTICE PLATFORM · CLASSES 6–12',
                  style: AppTypography.sectionLabel(c.accent)),
              const SizedBox(height: 16),
              // Headline with highlighted "work" and muted "watching".
              _Headline(),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.bodyLarge(c.textMuted),
                    children: [
                      const TextSpan(text: 'Ten focused minutes of '),
                      TextSpan(
                          text: 'adaptive practice',
                          style: AppTypography.serifEmphasis(c.textPrimary, size: 17)),
                      const TextSpan(
                          text: ' beats an hour of videos. Askaide asks you one question '
                              'at a time, meets you where you are, and adjusts as you go.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Live stats
              Wrap(
                spacing: 28,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(color: c.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('LIVE', style: AppTypography.mono(c.success, size: 9)),
                  ]),
                  _Stat(value: '63+', label: 'students learning'),
                  _Stat(value: '10,000+', label: 'questions answered'),
                  Text('CBSE · ICSE · State',
                      style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 22, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 32),
              // CTAs
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => context.go(RoutePaths.tryNow),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Start a free session', style: AppTypography.button(Colors.white)),
                      const SizedBox(width: 8),
                      Text('→', style: AppTypography.serifEmphasis(Colors.white, size: 16)),
                    ]),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go(RoutePaths.forSchools),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('See school pricing', style: AppTypography.button(c.textPrimary)),
                      const SizedBox(width: 6),
                      Text('→', style: AppTypography.serifEmphasis(c.textPrimary, size: 16)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.shield, size: 14, color: c.accent),
                const SizedBox(width: 8),
                Text('Free forever  •  No credit card', style: AppTypography.bodySmall(c.textMuted)),
              ]),
              const SizedBox(height: 20),
              Text('do, don\'t watch', style: AppTypography.mono(c.accent, size: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = context.isDesktop ? 72.0 : 44.0;
    return RichText(
      text: TextSpan(
        style: AppTypography.display(c.textPrimary).copyWith(fontSize: size, height: 0.96),
        children: [
          const TextSpan(text: 'Do the\n'),
          TextSpan(
            text: 'work',
            style: AppTypography.display(c.textPrimary).copyWith(
              fontSize: size,
              height: 0.96,
              fontStyle: FontStyle.italic,
              background: Paint()..color = c.accentSecondary.withValues(alpha: 0.75),
            ),
          ),
          const TextSpan(text: ',\nnot the '),
          TextSpan(text: 'watching.', style: AppTypography.display(c.textMuted).copyWith(fontSize: size, height: 0.96)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 22, fontWeight: FontWeight.w500)),
        Text(label, style: AppTypography.bodySmall(c.textMuted).copyWith(fontSize: 12)),
      ],
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const items = ['CBSE', 'ICSE', 'STATE BOARDS', 'NCERT', 'CLASSES 6–12', 'ADAPTIVE AI'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border(
          top: BorderSide(color: c.border),
          bottom: BorderSide(color: c.border),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 32,
        runSpacing: 8,
        children: [
          for (final s in items)
            Text(s, style: AppTypography.mono(c.textPrimary, size: 10).copyWith(
                color: c.textPrimary.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: AppTypography.h2(c.textPrimary),
                  children: [
                    const TextSpan(text: 'Why practice beats '),
                    TextSpan(text: 'watching.', style: AppTypography.serifEmphasis(c.textPrimary, size: 32)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(builder: (context, cons) {
                final cols = cons.maxWidth > 760 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: cols == 3 ? 1.05 : 2.2,
                  children: const [
                    _Feature(icon: LucideIcons.sparkles, title: 'AI-generated questions', body: 'Fresh, curriculum-aligned questions every session — never the same drill twice.'),
                    _Feature(icon: LucideIcons.trendingUp, title: 'Adaptive difficulty', body: 'Meets you where you are and steps up as you improve, one question at a time.'),
                    _Feature(icon: LucideIcons.zap, title: 'Instant feedback', body: 'Know right away — with explanations that turn mistakes into mastery.'),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: c.accent),
          const SizedBox(height: 14),
          Text(title,
              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Flexible(
            child: Text(body,
                style: AppTypography.bodyMedium(c.textMuted),
                maxLines: 4, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CtaBand extends StatelessWidget {
  const _CtaBand();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      color: c.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Text('Start learning, free.',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1(c.bgPrimary).copyWith(fontSize: 44)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(RoutePaths.signup),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Create your account', style: AppTypography.button(Colors.white)),
                  const SizedBox(width: 8),
                  Text('→', style: AppTypography.serifEmphasis(Colors.white, size: 16)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
