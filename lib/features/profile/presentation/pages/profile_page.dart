import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../dashboard/data/dashboard_models.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../dashboard/presentation/widgets/dashboard_shared_widgets.dart';
import '../cubit/profile_cubit.dart';

/// Shimmer skeleton matching the profile page's box layout.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonProfileHeader(),
          const SizedBox(height: 20),
          // Streak placeholder
          Center(
            child: Container(
              width: 120,
              height: 46,
              decoration: BoxDecoration(
                color: c.bgCard,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.border),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Section label
          const SkeletonBox(width: 80, height: 11),
          const SizedBox(height: 12),
          // Stats grid (4 across)
          LayoutBuilder(
            builder: (context, cons) {
              final w = (cons.maxWidth - 36) / 4;
              return Row(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: EdgeInsets.only(left: _ > 0 ? 12 : 0),
                    child: SizedBox(width: w, child: const SkeletonStatCard(aspectRatio: 1.05)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Section label
          const SkeletonBox(width: 60, height: 11),
          const SizedBox(height: 12),
          // Badges area
          const SkeletonShellCard(
            showIcon: true,
            height: 220,
            child: Column(
              children: [
                SkeletonBox(width: double.infinity, height: 6, radius: 99),
                SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonCircle(size: 48),
                    SkeletonCircle(size: 48),
                    SkeletonCircle(size: 48),
                    SkeletonCircle(size: 48),
                    SkeletonCircle(size: 48),
                    SkeletonCircle(size: 48),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Section label
          const SkeletonBox(width: 100, height: 11),
          const SizedBox(height: 12),
          // Referral card
          const SkeletonShellCard(
            showIcon: true,
            showSubtitle: true,
            height: 200,
          ),
        ],
      ),
    );
  }
}

/// `/profile` — mirrors the frontend Profile page: identity header (avatar,
/// name, email, join date), the full streak display, an activity stats grid
/// (study hours / sessions / avg score ring / questions), the achievements
/// (badges) grid, and a referral card. Stats/streak/badges/referral are wired
/// to the same live [DashboardData] the dashboard uses.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (_) {
        final cubit = sl<DashboardCubit>();
        final userId = context.read<ProfileCubit>().state.user?.id ?? '';
        cubit.load(userId);
        return cubit;
      },
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.select<ProfileCubit, dynamic>((p) => p.state.user);
    final dashState = context.watch<DashboardCubit>().state;
    final data = dashState.data;
    final loading = dashState.status == DashboardStatus.initial ||
        dashState.status == DashboardStatus.loading;

    final today = DateTime.now();
    final practicedToday = data.todayQuestions > 0 ||
        data.practiceDates.any((d) =>
            d.year == today.year && d.month == today.month && d.day == today.day);

    return BlocListener<ProfileCubit, ProfileState>(
      // The user id may arrive after first build; (re)load stats once it does.
      listenWhen: (p, n) => p.user?.id != n.user?.id,
      listener: (context, profile) {
        final id = profile.user?.id ?? '';
        if (id.isNotEmpty) context.read<DashboardCubit>().load(id);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile header ──
                const _SectionLabel('Profile'),
                const SizedBox(height: 12),
                _HeaderCard(user: user),
                const SizedBox(height: 24),

                // ── Streak ──
                Center(
                  child: StreakDisplay(
                    data: data,
                    practicedToday: practicedToday,
                    loading: loading,
                  ),
                ),
                // Loss-aversion nudge when the streak is at risk.
                if (!loading && !practicedToday && data.currentStreak > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8722A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE8722A).withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Practice today to save your ${data.currentStreak}-day streak!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(const Color(0xFFE8722A)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (loading)
                  const _ProfileSkeleton()
                else ...[
                  // ── Activity stats ──
                  const _SectionLabel('Activity'),
                  const SizedBox(height: 12),
                  LayoutBuilder(builder: (context, cons) {
                    final cols = cons.maxWidth > 540 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        // Study hours & sessions come from `user.additionalDetails`
                        // on the frontend; they are not yet in the Flutter data
                        // layer, so they fall back to 0 (as the frontend does).
                        const _StatCard(
                            icon: LucideIcons.clock, value: '0', label: 'Study Hours'),
                        const _StatCard(
                            icon: LucideIcons.bookOpen, value: '0', label: 'Sessions'),
                        _StatCard.gauge(
                            percent: data.accuracyPercent.toDouble(), label: 'Avg Score'),
                        _StatCard(
                            icon: LucideIcons.target,
                            value: '${data.totalQuestions}',
                            label: 'Questions'),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),

                  // ── Badges ──
                  const _SectionLabel('Badges'),
                  const SizedBox(height: 12),
                  AchievementsCard(earned: data.badges),
                  const SizedBox(height: 24),

                  // ── Referral ──
                  const _SectionLabel('Refer a friend'),
                  const SizedBox(height: 12),
                  _ReferralCard(referral: data.referral),
                  const SizedBox(height: 16),

                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(RoutePaths.settings),
                      icon: Icon(LucideIcons.settings, size: 16, color: c.textPrimary),
                      label: Text('Edit in Settings', style: AppTypography.button(c.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A mono uppercase "— Label" section heading, matching the frontend.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text('— ${text.toUpperCase()}',
        style: AppTypography.sectionLabel(context.colors.textMuted));
  }
}

/// Identity header — avatar tile, name, email and join date.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final image = user?.image as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: context.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: c.accentLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.border),
              image: (image != null && image.isNotEmpty)
                  ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: (image == null || image.isEmpty)
                ? Icon(LucideIcons.user, size: 44, color: c.accent)
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.userName ?? user?.name ?? 'Student',
                    style: AppTypography.h2(c.textPrimary).copyWith(fontSize: 26)),
                const SizedBox(height: 6),
                _IconLine(icon: LucideIcons.mail, text: user?.email ?? '—'),
                const SizedBox(height: 4),
                // The frontend shows the join month; the Flutter user model has
                // no createdAt yet, so this mirrors its "Recently" fallback.
                const _IconLine(icon: LucideIcons.calendar, text: 'Joined Recently'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.accentLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(user?.accountType.label ?? 'Student',
                      style: AppTypography.mono(c.accent, size: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium(c.textMuted)),
        ),
      ],
    );
  }
}

/// A single activity stat tile: an accent icon (or circular gauge) above a
/// large number and a mono uppercase label.
class _StatCard extends StatelessWidget {
  const _StatCard({this.icon, required this.value, required this.label})
      : percent = null;
  const _StatCard.gauge({required double this.percent, required this.label})
      : icon = null,
        value = '';

  final IconData? icon;
  final String value;
  final String label;
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (percent != null)
            CircularGauge(percent: percent!, color: c.accent, size: 64)
          else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.accentLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.border),
              ),
              child: Icon(icon, size: 20, color: c.accent),
            ),
            const SizedBox(height: 10),
            Text(value, style: AppTypography.statNumber(c.textPrimary, size: 26)),
          ],
          const SizedBox(height: 6),
          Text(label.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.mono(c.textMuted, size: 9).copyWith(letterSpacing: 1)),
        ],
      ),
    );
  }
}

/// Referral invite card — gradient top accent, code in a dashed box, share CTA.
class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referral});
  final ReferralSummary? referral;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasCode = referral != null && referral!.code.isNotEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.accent, c.accentSecondary]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GradientIcon(LucideIcons.gift, secondary: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Refer a Friend',
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 15)),
                          Text('Both get a streak freeze!',
                              style: AppTypography.bodySmall(c.textSecondary)),
                        ],
                      ),
                    ),
                    if (referral != null && referral!.totalReferrals > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.accentLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.users, size: 13, color: c.accent),
                          const SizedBox(width: 4),
                          Text('${referral!.totalReferrals}',
                              style: AppTypography.mono(c.accent, size: 11)),
                        ]),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (hasCode) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your referral code', style: AppTypography.bodySmall(c.textMuted)),
                        const SizedBox(height: 8),
                        DottedBorderBox(
                          color: c.border,
                          child: Center(
                            child: Text(referral!.code,
                                style: AppTypography.mono(c.textPrimary, size: 18)
                                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Invite friends — you both get a streak freeze.',
                        style: AppTypography.bodySmall(c.textMuted)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (hasCode) {
                        Clipboard.setData(ClipboardData(
                          text:
                              '🎯 Join me on AskAide — AI-powered practice for CBSE students! '
                              'Use my referral code: ${referral!.code} and we both get a streak freeze!',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Referral message copied!')),
                        );
                      } else {
                        context.go(RoutePaths.referral);
                      }
                    },
                    icon: const Icon(LucideIcons.share2, size: 15),
                    label: Text(hasCode ? 'Share & Earn' : 'Refer & Earn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A box with a dashed border (for the referral code).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, required this.color});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, radius: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, this.radius = 8});
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}
