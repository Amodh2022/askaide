import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: c.accentLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(LucideIcons.gift, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text('Refer a friend, both win!',
                        style: AppTypography.h2(c.textPrimary).copyWith(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text('Share your code — when a friend joins, you both earn streak freezes.',
                        style: AppTypography.bodyLarge(c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  _RefStat(value: '${info.redeemCount}', label: 'REFERRALS'),
                  const SizedBox(width: 12),
                  _RefStat(value: '${info.redeemCount}', label: 'REWARDS'),
                  const SizedBox(width: 12),
                  _RefStat(value: '${info.dailyGoal}', label: 'DAILY GOAL'),
                ],
              ),
              const SizedBox(height: 16),

              // Referral code + link
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: context.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR REFERRAL CODE', style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: 8),
                    _CopyRow(value: code, label: 'code'),
                    const SizedBox(height: 16),
                    Text('SHARE LINK', style: AppTypography.mono(c.textMuted, size: 10)),
                    const SizedBox(height: 8),
                    _CopyRow(value: link, label: 'link'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            const SizedBox(height: 4),
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
        borderRadius: BorderRadius.circular(4),
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
