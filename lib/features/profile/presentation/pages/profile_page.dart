import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/profile_cubit.dart';

/// `/profile` — identity header (avatar, name, email, role), a stats grid, and
/// an achievements section. Mirrors the frontend Profile page.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.select<ProfileCubit, dynamic>((p) => p.state.user);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identity header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: context.cardDecoration(),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: c.accentLight,
                      child: Text(user?.initials ?? 'U',
                          style: AppTypography.h3(c.accent)),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Student',
                              style: AppTypography.h2(c.textPrimary).copyWith(fontSize: 28)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(LucideIcons.mail, size: 14, color: c.textMuted),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(user?.email ?? '—',
                                    style: AppTypography.bodyMedium(c.textMuted)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
              ),
              const SizedBox(height: 16),

              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
                children: const [
                  _Stat(value: '0h', label: 'Study time'),
                  _Stat(value: '0', label: 'Sessions'),
                  _Stat(value: '—', label: 'Avg. score'),
                  _Stat(value: '0', label: 'Questions'),
                ],
              ),
              const SizedBox(height: 16),

              // Achievements
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: context.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.award, size: 18, color: c.accent),
                        const SizedBox(width: 8),
                        Text('Achievements',
                            style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Earn badges as you practise — your first one is moments away.',
                        style: AppTypography.bodyMedium(c.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.go(RoutePaths.settings),
                icon: Icon(LucideIcons.settings, size: 16, color: c.textPrimary),
                label: Text('Edit in Settings', style: AppTypography.button(c.textPrimary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTypography.statNumber(c.textPrimary, size: 28)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.bodySmall(c.textMuted)),
        ],
      ),
    );
  }
}
