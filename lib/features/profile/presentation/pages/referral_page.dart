import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/page_scroll_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../referral/referral_feature.dart';

/// `/referral` — Refer & Earn: hero, stats, and a copyable referral code/link.
/// Mirrors the frontend ReferralPage, wired to the live referral code.
class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReferralCubit>(
      create: (_) => sl<ReferralCubit>()..load(),
      child: const _ReferralView(),
    );
  }
}

class _ReferralView extends StatelessWidget {
  const _ReferralView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final info = context.watch<ReferralCubit>().state.info;
    final code = info.code.isEmpty ? 'ASKAIDE-FRIEND' : info.code;
    final link = 'https://askaide.ai/signup?ref=$code';

    return PageScrollScaffold(
      maxWidth: 720,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: AppRadii.modalR,
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: c.accent, borderRadius: AppRadii.componentR),
                      child: const Icon(LucideIcons.gift, color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Refer a friend, both win!',
                        style: AppTypography.h2(c.textPrimary).copyWith(fontSize: 28)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Share your code — when a friend joins, you both earn streak freezes.',
                        style: AppTypography.bodyLarge(c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats
              Row(
                children: [
                  _RefStat(value: '${info.redeemCount}', label: 'REFERRALS'),
                  const SizedBox(width: AppSpacing.sm),
                  _RefStat(value: '${info.redeemCount}', label: 'REWARDS'),
                  const SizedBox(width: AppSpacing.sm),
                  _RefStat(value: '${info.dailyGoal}', label: 'DAILY GOAL'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Referral code + link
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: context.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR REFERRAL CODE', style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: AppSpacing.xs),
                    _CopyRow(value: code, label: 'code'),
                    const SizedBox(height: AppSpacing.md),
                    Text('SHARE LINK', style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: AppSpacing.xs),
                    _CopyRow(value: link, label: 'link'),
                  ],
                ),
              ),
            ],
    );
  }
}

class _RefStat extends StatelessWidget {
  const _RefStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.statNumber(c.accent, size: 28)),
            const SizedBox(height: AppSpacing.xxs),
            Text(label, style: AppTypography.mono(c.textMuted, size: 10)),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border.all(color: c.border),
        borderRadius: AppRadii.cardR,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.mono(c.textPrimary, size: 13)),
          ),
          IconButton(
            icon: Icon(LucideIcons.copy, size: 18, color: c.accent),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Copied $label!')));
            },
          ),
        ],
      ),
    );
  }
}
