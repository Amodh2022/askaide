import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../ai_assistant/domain/repositories/ai_assistant_repository.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../parent/parent_feature.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/teacher_feature.dart';

// ─── helpers ──────────────────────────────────────────────────────────────────

String _subjectEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('math')) return '📐';
  if (n.contains('physics')) return '⚛️';
  if (n.contains('chem')) return '🧪';
  if (n.contains('bio')) return '🧬';
  if (n.contains('english')) return '📚';
  if (n.contains('hindi')) return '🔤';
  if (n.contains('hist')) return '🏛️';
  if (n.contains('geo')) return '🌍';
  return '📖';
}

String _relativeTime(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.day}';
}

String _statusLabel(String raw) {
  switch (raw.toUpperCase()) {
    case 'STRONG': return 'Strong';
    case 'ON_TRACK': return 'On Track';
    case 'NEEDS_ATTENTION': return 'Needs Attention';
    case 'NEEDS_REVISION': return 'Needs Revision';
    case 'NEEDS_HELP': return 'Needs Help';
    case 'MASTERED': return 'Mastered';
    case 'PRACTICING': return 'Practicing';
    case 'LEARNING': return 'Learning';
    case 'WEAK': return 'Weak';
    case 'INACTIVE': return 'Inactive';
    case 'NOT_STARTED': return 'Not Started';
    case 'HIGH_PRIORITY': return 'High Priority';
    case 'MEDIUM_PRIORITY': return 'Medium Priority';
    case 'MONITOR': return 'Monitor';
    default: return raw;
  }
}

Color _statusColor(String raw, AskAideColors c) {
  switch (raw.toUpperCase()) {
    case 'STRONG':
    case 'MASTERED':
      return c.accent;
    case 'ON_TRACK':
    case 'PRACTICING':
    case 'LEARNING':
      return c.warning;
    case 'NEEDS_ATTENTION':
    case 'NEEDS_REVISION':
    case 'MEDIUM_PRIORITY':
    case 'MONITOR':
      return c.warning;
    case 'WEAK':
    case 'NEEDS_HELP':
    case 'HIGH_PRIORITY':
      return c.danger;
    case 'INACTIVE':
    case 'NOT_STARTED':
      return c.textMuted;
    default:
      return c.textMuted;
  }
}

// ─── shared widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _statusColor(status, c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(_statusLabel(status), style: AppTypography.mono(color, size: 9)),
    );
  }
}

/// Fill colour for a mastery [ProgressBar], matching the frontend's
/// `getBarColor` thresholds. [v] is a 0–1 fraction.
Color _masteryBarColor(double v, AskAideColors c) {
  final pct = v * 100;
  if (pct >= 70) return c.accent;
  if (pct >= 50) return c.warning;
  if (pct >= 30) return c.textMuted;
  return c.danger;
}

/// Circular mastery ring with the percentage in the centre — mirrors the
/// frontend's `MasteryGauge` (SVG ring). [value] is 0–1, or 0–100 when
/// [isPercentage] is true. Colour follows the same mastery thresholds as React.
enum _GaugeSize { sm, md, lg, xl }

class _MasteryGauge extends StatelessWidget {
  const _MasteryGauge({
    required this.value,
    this.size = _GaugeSize.md,
    this.label,
  });

  final double value;
  final _GaugeSize size;
  final String? label;

  static ({double width, double stroke, double font}) _dims(_GaugeSize s) =>
      switch (s) {
        _GaugeSize.sm => (width: 48, stroke: 4, font: 12),
        _GaugeSize.md => (width: 64, stroke: 5, font: 14),
        _GaugeSize.lg => (width: 80, stroke: 6, font: 16),
        _GaugeSize.xl => (width: 120, stroke: 8, font: 20),
      };

  static Color _color(double v, AskAideColors c) {
    if (v >= 0.7) return c.success;
    if (v >= 0.5) return c.warning;
    if (v >= 0.3) return const Color(0xFF8B5CF6); // purple (no matching token)
    return c.danger;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final normalized = value.clamp(0.0, 1.0);
    final pct = (normalized * 100).round();
    final d = _dims(size);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: d.width,
          height: d.width,
          child: CustomPaint(
            painter: _GaugePainter(
              progress: normalized,
              stroke: d.stroke,
              trackColor: c.border,
              progressColor: _color(normalized, c),
            ),
            child: Center(
              child: Text('$pct%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: d.font,
                    color: c.textPrimary,
                  )),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(label!, style: AppTypography.bodySmall(c.textSecondary), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.stroke,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final double stroke;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    // Start at top (-90°) and sweep clockwise, matching the SVG gauge.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor ||
      old.stroke != stroke;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.icon, required this.label, required this.value, this.sub, this.danger = false});
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final iconColor = danger ? c.danger : c.accent;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: context.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTypography.statNumber(iconColor, size: 22)),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.mono(c.textMuted, size: 9),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!, style: AppTypography.bodySmall(c.textMuted), maxLines: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.value, required this.label});
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTypography.statNumber(c.accent, size: 28)),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.mono(c.textMuted, size: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap, this.filled = false, this.danger = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = filled ? c.accent : danger ? c.danger.withValues(alpha: 0.1) : c.bgCard;
    final fg = filled ? Colors.white : danger ? c.danger : c.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: filled ? c.accent : danger ? c.danger.withValues(alpha: 0.4) : c.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.bodySmall(fg).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Teacher Dashboard (Subject Selector) ─────────────────────────────────────

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMock = context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<TeacherHomeCubit>(
      create: (_) => sl<TeacherHomeCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', mock: isMock),
      child: const _TeacherHomeView(),
    );
  }
}

class _TeacherHomeView extends StatelessWidget {
  const _TeacherHomeView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    final today = '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return BlocBuilder<TeacherHomeCubit, TeacherHomeState>(
      builder: (context, state) {
        final data = state.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TEACHER DASHBOARD', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 6),
                  Text('Your class, today.',
                      style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (data.teacherName.isNotEmpty) data.teacherName,
                      if (data.schoolName.isNotEmpty) data.schoolName,
                      today,
                    ].join(' · '),
                    style: AppTypography.bodySmall(c.textMuted),
                  ),
                  const SizedBox(height: 20),

                  if (state.status == TLoad.loading) ...[
                    const SkeletonListLoader(padding: EdgeInsets.all(24)),
                  ] else ...[
                    // Quick actions
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ActionButton(
                          label: 'Quizzes',
                          icon: LucideIcons.clipboardList,
                          onTap: () => context.go('/teacher/quizzes'),
                          filled: true,
                        ),
                        _ActionButton(
                          label: 'Question Papers',
                          icon: LucideIcons.fileText,
                          onTap: () => context.go('/question-paper'),
                        ),
                        _ActionButton(
                          label: 'AI Generator',
                          icon: LucideIcons.sparkles,
                          onTap: () => context.go('/teacher/ai-generator'),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.accentLight,
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${data.assignments.length}',
                                  style: AppTypography.mono(c.accent, size: 12).copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('Subjects', style: AppTypography.bodySmall(c.accent)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.accentLight,
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${data.totalStudentsAcrossSubjects}',
                                  style: AppTypography.mono(c.accent, size: 12).copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('Students', style: AppTypography.bodySmall(c.accent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (data.assignments.isEmpty)
                      Container(
                        width: double.infinity,
                        decoration: context.cardDecoration(),
                        child: const EmptyState(
                          icon: LucideIcons.users,
                          title: 'No assigned subjects',
                          hint: 'Subjects assigned to you by an admin will appear here.',
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Icon(LucideIcons.bookOpen, size: 16, color: c.accent),
                          const SizedBox(width: 8),
                          Text('My Subjects',
                              style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Responsive grid: two columns on tablet+ widths, single
                      // column on phones (mirrors React's md:grid-cols-2).
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 12.0;
                          final twoCol = constraints.maxWidth >= 640;
                          final cardW = twoCol
                              ? (constraints.maxWidth - gap) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final a in data.assignments)
                                SizedBox(
                                    width: cardW, child: _SubjectCard(assignment: a)),
                            ],
                          );
                        },
                      ),
                    ],
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

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.assignment});
  final TeacherAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final emoji = _subjectEmoji(assignment.subjectName);
    return GestureDetector(
      onTap: () => context.go('/teacher/subject/${assignment.subjectId}'),
      child: Container(
        decoration: context.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: double.infinity,
              color: c.accentLight,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.users, size: 11, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('${assignment.totalStudents}',
                            style: AppTypography.mono(c.textMuted, size: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment.subjectName,
                      style: AppTypography.labelLarge(c.textPrimary).copyWith(fontSize: 17)),
                  const SizedBox(height: 6),
                  for (final cls in assignment.classes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(LucideIcons.graduationCap, size: 13, color: c.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${cls.className}${cls.sections.isNotEmpty ? ' · ${cls.sections.map((s) => s.name).join(', ')} sections' : ''}',
                              style: AppTypography.bodySmall(c.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('View Dashboard',
                          style: AppTypography.bodySmall(c.accent).copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronRight, size: 13, color: c.accent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Teacher Subject Page ──────────────────────────────────────────────────────

class TeacherSubjectPage extends StatelessWidget {
  const TeacherSubjectPage({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final isMock = context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<TeacherSubjectCubit>(
      create: (_) => sl<TeacherSubjectCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', subjectId, mock: isMock),
      child: _TeacherSubjectView(subjectId: subjectId),
    );
  }
}

class _TeacherSubjectView extends StatelessWidget {
  const _TeacherSubjectView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherSubjectCubit, TeacherSubjectState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) return const SkeletonListLoader();
        final d = state.dashboard;
        final inactiveCount = d.totalStudents - d.activeThisWeek;
        final atRisk = d.studentsNeedingHelp;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Teacher Dashboard', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('SUBJECT DASHBOARD', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 4),
                  Text(d.subjectName.isEmpty ? 'Subject' : d.subjectName,
                      style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionButton(
                        label: 'Students',
                        icon: LucideIcons.users,
                        onTap: () => context.go('/teacher/subject/$subjectId/students'),
                        filled: true,
                      ),
                      _ActionButton(
                        label: 'Weak Topics',
                        icon: LucideIcons.triangleAlert,
                        onTap: () => context.go('/teacher/subject/$subjectId/weak-topics'),
                        danger: true,
                      ),
                      _ActionButton(
                        label: 'Activity',
                        icon: LucideIcons.activity,
                        onTap: () => context.go('/teacher/subject/$subjectId/activity'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // KPI cards
                  Row(
                    children: [
                      _KpiCard(
                        icon: LucideIcons.users,
                        label: 'Total Students',
                        value: '${d.totalStudents}',
                        sub: '${d.activeThisWeek} active this week',
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        icon: LucideIcons.trendingUp,
                        label: 'Avg Mastery',
                        value: '${(d.avgMastery * 100).round()}%',
                        sub: '${(d.avgCoverage * 100).round()}% coverage',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _KpiCard(
                        icon: LucideIcons.barChart3,
                        label: 'Coverage',
                        value: '${(d.avgCoverage * 100).round()}%',
                        sub: 'Syllabus covered',
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        icon: LucideIcons.triangleAlert,
                        label: 'Need Help',
                        value: '${d.studentsNeedingHelp}',
                        sub: 'Students struggling',
                        danger: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // At-risk alert
                  if (inactiveCount > 0 || atRisk > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.danger.withValues(alpha: 0.08),
                        border: Border.all(color: c.danger.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.triangleAlert, size: 15, color: c.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 20,
                              children: [
                                if (inactiveCount > 0)
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: '$inactiveCount',
                                        style: AppTypography.mono(c.danger, size: 12).copyWith(fontWeight: FontWeight.w700)),
                                    TextSpan(
                                        text: ' student${inactiveCount > 1 ? 's' : ''} inactive this week',
                                        style: AppTypography.bodySmall(c.textPrimary)),
                                  ])),
                                if (atRisk > 0)
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: '$atRisk',
                                        style: AppTypography.mono(c.danger, size: 12).copyWith(fontWeight: FontWeight.w700)),
                                    TextSpan(
                                        text: ' student${atRisk > 1 ? 's' : ''} need extra help',
                                        style: AppTypography.bodySmall(c.textPrimary)),
                                  ])),
                              ],
                            ),
                          ),
                          if (atRisk > 0) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.go('/teacher/subject/$subjectId/students'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(4)),
                                child: Text('View', style: AppTypography.mono(Colors.white, size: 10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Chapter Progress
                  Row(
                    children: [
                      Icon(LucideIcons.bookOpen, size: 15, color: c.accent),
                      const SizedBox(width: 8),
                      Text('Chapter Progress',
                          style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                      const Spacer(),
                      Text('${d.chapterProgress.length} chapters',
                          style: AppTypography.mono(c.textMuted, size: 10)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (d.chapterProgress.isEmpty)
                    Text('No chapter data.', style: AppTypography.bodyMedium(c.textMuted))
                  else
                    for (final ch in d.chapterProgress)
                      _ChapterProgressCard(chapter: ch, subjectId: subjectId),

                  const SizedBox(height: 24),

                  // Top Weak Topics
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Top Weak Topics',
                                style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.go('/teacher/subject/$subjectId/weak-topics'),
                              child: Text('View All',
                                  style: AppTypography.bodySmall(c.accent).copyWith(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (d.topWeakTopics.isEmpty)
                          Text('No weak topics — great work!', style: AppTypography.bodySmall(c.textMuted))
                        else
                          for (final t in d.topWeakTopics.take(3))
                            _WeakTopicChip(topic: t),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Class Summary
                  if (d.classSummary.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: context.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.listChecks, size: 15, color: c.accent),
                              const SizedBox(width: 8),
                              Text('Class Summary',
                                  style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < d.classSummary.length; i++) ...[
                            _ClassSummaryRow(item: d.classSummary[i]),
                            if (i < d.classSummary.length - 1)
                              Divider(color: c.border, height: 1),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChapterProgressCard extends StatelessWidget {
  const _ChapterProgressCard({required this.chapter, required this.subjectId});
  final ChapterProgress chapter;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final masteryPct = (chapter.classAvgMastery * 100).round();

    return GestureDetector(
      onTap: () => context.go('/teacher/subject/$subjectId/chapter/${chapter.chapterId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: context.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c.bgCard,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                chapter.order.toString().padLeft(2, '0'),
                style: AppTypography.mono(c.textMuted, size: 12).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(chapter.name,
                            style: AppTypography.bodyMedium(c.textPrimary).copyWith(fontWeight: FontWeight.w500),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      if (chapter.status.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _StatusBadge(chapter.status),
                      ],
                      const SizedBox(width: 8),
                      // Avg mastery, folded into the title row so the chapter
                      // name keeps full width on narrow (mobile) layouts.
                      Text('$masteryPct%',
                          style: AppTypography.mono(c.accent, size: 15)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Single mastery bar (mirrors the frontend's ProgressBar).
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      height: 4,
                      color: c.border,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: chapter.classAvgMastery.clamp(0.0, 1.0),
                          child: ColoredBox(color: _masteryBarColor(chapter.classAvgMastery, c)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
                          const SizedBox(width: 3),
                          Text('${chapter.studentsCompleted} done', style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle)),
                          const SizedBox(width: 3),
                          Text('${chapter.studentsInProgress} in progress', style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: c.border, shape: BoxShape.circle)),
                          const SizedBox(width: 3),
                          Text('${chapter.studentsNotStarted} not started', style: AppTypography.bodySmall(c.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _WeakTopicChip extends StatelessWidget {
  const _WeakTopicChip({required this.topic});
  final TopWeakTopicItem topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.name,
                    style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(topic.chapterName, style: AppTypography.bodySmall(c.textMuted), maxLines: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(LucideIcons.triangleAlert, size: 13, color: c.danger),
          const SizedBox(width: 4),
          Text('${topic.studentsWeak}',
              style: AppTypography.mono(c.danger, size: 11).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text('weak', style: AppTypography.bodySmall(c.textMuted)),
        ],
      ),
    );
  }
}

class _ClassSummaryRow extends StatelessWidget {
  const _ClassSummaryRow({required this.item});
  final ClassSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: c.accentLight, borderRadius: BorderRadius.circular(4)),
            child: Icon(LucideIcons.users, size: 14, color: c.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.className} — ${item.sectionName}',
                    style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                Text('${item.studentCount} students', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(item.avgMastery * 100).round()}%',
                  style: AppTypography.mono(c.accent, size: 13).copyWith(fontWeight: FontWeight.w700)),
              Text('mastery', style: AppTypography.bodySmall(c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Teacher Students Page ─────────────────────────────────────────────────────

class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final isMock = context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<TeacherStudentsCubit>(
      create: (_) => sl<TeacherStudentsCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', subjectId, mock: isMock),
      child: _TeacherStudentsView(subjectId: subjectId),
    );
  }
}

class _TeacherStudentsView extends StatefulWidget {
  const _TeacherStudentsView({required this.subjectId});
  final String subjectId;

  @override
  State<_TeacherStudentsView> createState() => _TeacherStudentsViewState();
}

class _TeacherStudentsViewState extends State<_TeacherStudentsView> {
  String _search = '';
  String _statusFilter = 'all';
  String _sortBy = 'mastery';
  bool _sortDesc = true;

  List<StudentRow> _filter(List<StudentRow> list) {
    var result = [...list];
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((s) =>
          s.name.toLowerCase().contains(q) || s.email.toLowerCase().contains(q)).toList();
    }
    if (_statusFilter != 'all') {
      result = result.where((s) {
        final st = s.status.toUpperCase();
        switch (_statusFilter) {
          case 'struggling': return st.contains('NEEDS') || st.contains('WEAK');
          case 'top': return st == 'STRONG';
          case 'inactive': return st == 'INACTIVE' || s.daysInactive > 3;
          default: return true;
        }
      }).toList();
    }
    result.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name': cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'coverage': cmp = a.coverage.compareTo(b.coverage);
        case 'lastActive': cmp = a.lastPracticed.compareTo(b.lastPracticed);
        default: cmp = a.mastery.compareTo(b.mastery);
      }
      return _sortDesc ? -cmp : cmp;
    });
    return result;
  }

  String _lastActive(String iso) {
    if (iso.isEmpty) return 'Never';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherStudentsCubit, TeacherStudentsState>(
      builder: (context, state) {
        final students = state.status == TLoad.loaded ? _filter(state.students) : <StudentRow>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/${widget.subjectId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Subject Dashboard', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('STUDENT ROSTER', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 4),
                  Text('Students', style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  Text('${state.totalCount} students enrolled', style: AppTypography.bodySmall(c.textMuted)),
                  const SizedBox(height: 16),

                  // Filters
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: AppTypography.bodySmall(c.textPrimary),
                    cursorColor: c.accent,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.bgCard,
                      hintText: 'Search students...',
                      hintStyle: AppTypography.bodySmall(c.textMuted),
                      prefixIcon: Icon(LucideIcons.search, size: 16, color: c.textMuted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c.accent)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownPill<String>(
                          value: _statusFilter,
                          items: const [
                            ('all', 'All Students'),
                            ('struggling', 'Struggling'),
                            ('top', 'Top Performers'),
                            ('inactive', 'Inactive'),
                          ],
                          onChanged: (v) => setState(() => _statusFilter = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DropdownPill<String>(
                          value: _sortBy,
                          items: const [
                            ('mastery', 'Sort: Mastery'),
                            ('name', 'Sort: Name'),
                            ('coverage', 'Sort: Coverage'),
                            ('lastActive', 'Sort: Last Active'),
                          ],
                          onChanged: (v) => setState(() => _sortBy = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _sortDesc = !_sortDesc),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.bgCard,
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(LucideIcons.arrowUpDown, size: 16, color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state.status == TLoad.loading)
                    const SkeletonListLoader()
                  else if (students.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: context.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(LucideIcons.users, size: 32, color: c.textMuted),
                          const SizedBox(height: 8),
                          Text('No students match', style: AppTypography.bodyMedium(c.textMuted)),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: context.cardDecoration(),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: c.bgCard,
                            child: Row(
                              children: [
                                Expanded(child: Text('STUDENT', style: AppTypography.mono(c.textMuted, size: 9))),
                                SizedBox(width: 70, child: Text('STATUS', style: AppTypography.mono(c.textMuted, size: 9))),
                                SizedBox(width: 60, child: Text('CHAPTERS', style: AppTypography.mono(c.textMuted, size: 9))),
                                SizedBox(width: 55, child: Text('MASTERY', style: AppTypography.mono(c.textMuted, size: 9))),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: c.border),
                          for (int i = 0; i < students.length; i++) ...[
                            _StudentTableRow(
                              student: students[i],
                              subjectId: widget.subjectId,
                              lastActiveLabel: _lastActive(students[i].lastPracticed),
                            ),
                            if (i < students.length - 1) Divider(height: 1, color: c.border),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StudentTableRow extends StatelessWidget {
  const _StudentTableRow({required this.student, required this.subjectId, required this.lastActiveLabel});
  final StudentRow student;
  final String subjectId;
  final String lastActiveLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = student.status.toUpperCase();
    final isTop = st == 'STRONG';
    final isStruggling = st.contains('NEEDS') || st.contains('WEAK');
    final statusColor = isTop ? c.accent : isStruggling ? c.danger : c.warning;
    final statusLabel = isTop ? 'Top' : isStruggling ? 'Struggling' : 'Active';

    return GestureDetector(
      onTap: () => context.go('/teacher/subject/$subjectId/student/${student.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name,
                            style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${student.className}${student.section.isNotEmpty ? ' — ${student.section}' : ''}',
                            style: AppTypography.bodySmall(c.textMuted), maxLines: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(statusLabel,
                    style: AppTypography.mono(statusColor, size: 8), textAlign: TextAlign.center),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text('${student.chaptersCompleted}/${student.totalChapters}',
                  style: AppTypography.mono(c.textPrimary, size: 11)),
            ),
            SizedBox(
              width: 55,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _MasteryGauge(value: student.mastery, size: _GaugeSize.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Teacher Chapter Analytics Page ───────────────────────────────────────────

class TeacherChapterPage extends StatelessWidget {
  const TeacherChapterPage({super.key, required this.subjectId, required this.chapterId});
  final String subjectId;
  final String chapterId;

  @override
  Widget build(BuildContext context) {
    final isMock = context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<TeacherChapterCubit>(
      create: (_) => sl<TeacherChapterCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', subjectId, chapterId, mock: isMock),
      child: _TeacherChapterView(subjectId: subjectId),
    );
  }
}

class _TeacherChapterView extends StatelessWidget {
  const _TeacherChapterView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherChapterCubit, TeacherChapterState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) return const SkeletonListLoader();
        final d = state.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/$subjectId'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Subject Dashboard', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Chapter ${d.chapterOrder}',
                        style: AppTypography.bodySmall(c.textMuted).copyWith(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  Text(d.chapterName.isEmpty ? 'Chapter Analytics' : d.chapterName,
                      style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _KpiCard(icon: LucideIcons.target, label: 'Total Topics', value: '${d.totalTopics}'),
                      const SizedBox(width: 8),
                      _KpiCard(icon: LucideIcons.trendingUp, label: 'Avg Mastery', value: '${(d.avgMastery * 100).round()}%'),
                      const SizedBox(width: 8),
                      _KpiCard(icon: LucideIcons.barChart3, label: 'Avg Coverage', value: '${d.avgCoverage.round()}%'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Icon(LucideIcons.barChart3, size: 16, color: c.accent),
                      const SizedBox(width: 8),
                      Text('Topic Breakdown', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final topic in d.topics) _TopicAnalyticsCard(topic: topic),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.triangleAlert, size: 15, color: c.danger),
                            const SizedBox(width: 8),
                            Text('Struggling Students (${d.strugglingStudents.length})',
                                style: AppTypography.labelLarge(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (d.strugglingStudents.isEmpty)
                          Text('No struggling students — great! 🎉', style: AppTypography.bodySmall(c.textMuted))
                        else
                          for (final s in d.strugglingStudents) _StrugglingStudentCard(student: s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopicAnalyticsCard extends StatelessWidget {
  const _TopicAnalyticsCard({required this.topic});
  final ChapterAnalyticsTopic topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dist = topic.distribution;
    final total = dist.total;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(topic.name,
                          style: AppTypography.bodyMedium(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    if (topic.status.isNotEmpty) _StatusBadge(topic.status),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${topic.studentsAttempted}/${topic.studentsTotal}',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(width: 8),
              Text('${(topic.classAvgMastery * 100).round()}% avg',
                  style: AppTypography.mono(c.accent, size: 11).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (dist.mastered > 0)
                      Flexible(flex: dist.mastered, child: ColoredBox(color: c.accent)),
                    if (dist.practicing > 0)
                      Flexible(flex: dist.practicing, child: const ColoredBox(color: Colors.blue)),
                    if (dist.learning > 0)
                      Flexible(flex: dist.learning, child: const ColoredBox(color: Colors.purple)),
                    if (dist.weak > 0)
                      Flexible(flex: dist.weak, child: ColoredBox(color: c.danger)),
                    Flexible(flex: total, child: const SizedBox()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: [
                _DistLegend(color: c.accent, label: 'Mastered', count: dist.mastered),
                _DistLegend(color: Colors.blue, label: 'Practicing', count: dist.practicing),
                _DistLegend(color: Colors.purple, label: 'Learning', count: dist.learning),
                _DistLegend(color: c.danger, label: 'Weak', count: dist.weak),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DistLegend extends StatelessWidget {
  const _DistLegend({required this.color, required this.label, required this.count});
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label ($count)', style: AppTypography.bodySmall(context.colors.textMuted)),
      ],
    );
  }
}

class _StrugglingStudentCard extends StatelessWidget {
  const _StrugglingStudentCard({required this.student});
  final StrugglingStudent student;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                Text('${student.weakTopics} weak topics', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          Text('${(student.masteryScore * 100).round()}%',
              style: AppTypography.mono(c.danger, size: 13).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Teacher Weak Topics Page ──────────────────────────────────────────────────

class TeacherWeakTopicsPage extends StatelessWidget {
  const TeacherWeakTopicsPage({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final isMock = context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<TeacherWeakTopicsCubit>(
      create: (_) => sl<TeacherWeakTopicsCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', subjectId, mock: isMock),
      child: _TeacherWeakTopicsView(subjectId: subjectId),
    );
  }
}

class _TeacherWeakTopicsView extends StatelessWidget {
  const _TeacherWeakTopicsView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherWeakTopicsCubit, TeacherWeakTopicsState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) return const SkeletonListLoader();
        final d = state.data;
        final highCount = d.topics.where((t) => t.teacherAction == 'HIGH_PRIORITY').length;
        final medCount = d.topics.where((t) => t.teacherAction == 'MEDIUM_PRIORITY').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/$subjectId'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Subject Dashboard', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('WEAK TOPICS REPORT', style: AppTypography.mono(c.textMuted, size: 10)),
                  const SizedBox(height: 4),
                  Text('Areas Needing Attention',
                      style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  Text('${d.totalWeakTopics} topic${d.totalWeakTopics != 1 ? 's' : ''} flagged for review',
                      style: AppTypography.bodySmall(c.textMuted)),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    children: [
                      if (highCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.danger.withValues(alpha: 0.1),
                            border: Border.all(color: c.danger),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$highCount',
                                  style: AppTypography.mono(c.danger, size: 11).copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('High Priority', style: AppTypography.bodySmall(c.danger)),
                            ],
                          ),
                        ),
                      if (medCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.warning.withValues(alpha: 0.1),
                            border: Border.all(color: c.warning),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$medCount',
                                  style: AppTypography.mono(c.warning, size: 11).copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('Medium Priority', style: AppTypography.bodySmall(c.warning)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (d.classroomRecommendation.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.accentLight,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.lightbulb, size: 18, color: c.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Classroom Recommendation',
                                    style: AppTypography.labelLarge(c.textPrimary)),
                                const SizedBox(height: 4),
                                Text(d.classroomRecommendation,
                                    style: AppTypography.bodyMedium(c.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (d.topics.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: context.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(LucideIcons.checkCircle, size: 32, color: c.accent),
                          const SizedBox(height: 8),
                          Text('No weak topics — great work!', style: AppTypography.bodyMedium(c.textMuted)),
                        ],
                      ),
                    )
                  else
                    for (final topic in d.topics) _WeakTopicDetailCard(topic: topic),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WeakTopicDetailCard extends StatelessWidget {
  const _WeakTopicDetailCard({required this.topic});
  final WeakTopicDetail topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final borderColor = topic.teacherAction == 'HIGH_PRIORITY'
        ? c.danger
        : topic.teacherAction == 'MEDIUM_PRIORITY' ? c.warning : c.accent;
    final bgColor = topic.teacherAction == 'HIGH_PRIORITY'
        ? c.danger.withValues(alpha: 0.07)
        : topic.teacherAction == 'MEDIUM_PRIORITY' ? c.warning.withValues(alpha: 0.07) : c.accentLight;

    // Rounded card with a full-height 3px left accent bar. A non-uniform
    // Border can't be combined with borderRadius in Flutter, so the accent is
    // a separate strip (mirrors the frontend's `border-l-4`).
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: borderColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(topic.name,
                              style: AppTypography.labelLarge(c.textPrimary).copyWith(fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(topic.teacherAction),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(topic.chapterName, style: AppTypography.bodySmall(c.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${topic.weakPercentage}%',
                      style: AppTypography.mono(borderColor, size: 22).copyWith(fontWeight: FontWeight.w700, height: 1)),
                  Text('students weak', style: AppTypography.bodySmall(c.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(LucideIcons.trendingDown, size: 13, color: borderColor),
              const SizedBox(width: 4),
              Text('${topic.studentsWeak} of ${topic.totalStudents} weak',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(width: 16),
              Icon(LucideIcons.target, size: 13, color: c.accent),
              const SizedBox(width: 4),
              Text('${(topic.avgMastery * 100).round()}% avg mastery',
                  style: AppTypography.bodySmall(c.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _DiffBar(label: 'Easy', value: topic.difficulty.easy, color: c.accent)),
              const SizedBox(width: 8),
              Expanded(child: _DiffBar(label: 'Medium', value: topic.difficulty.medium, color: c.warning)),
              const SizedBox(width: 8),
              Expanded(child: _DiffBar(label: 'Hard', value: topic.difficulty.hard, color: c.danger)),
            ],
          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffBar extends StatelessWidget {
  const _DiffBar({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.mono(c.textMuted, size: 9)),
            Text('${(value * 100).round()}%',
                style: AppTypography.mono(color, size: 9).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: c.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Teacher Activity Page ─────────────────────────────────────────────────────

class TeacherActivityPage extends StatelessWidget {
  const TeacherActivityPage({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final isMock = context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<TeacherActivityCubit>(
      create: (_) => sl<TeacherActivityCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', subjectId, mock: isMock),
      child: _TeacherActivityView(subjectId: subjectId),
    );
  }
}

class _TeacherActivityView extends StatelessWidget {
  const _TeacherActivityView({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherActivityCubit, TeacherActivityState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/$subjectId'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Subject Dashboard', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.activity, size: 22, color: c.accent),
                      const SizedBox(width: 8),
                      Text('Activity Feed',
                          style: AppTypography.h2(c.textPrimary).copyWith(fontWeight: FontWeight.w700, fontSize: 24)),
                    ],
                  ),
                  Text('Recent student activity', style: AppTypography.bodySmall(c.textMuted)),
                  const SizedBox(height: 20),

                  if (state.status == TLoad.loading)
                    const SkeletonListLoader()
                  else if (state.activities.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: context.cardDecoration(),
                      child: Column(
                        children: [
                          Icon(LucideIcons.activity, size: 32, color: c.textMuted),
                          const SizedBox(height: 8),
                          Text('No recent activity', style: AppTypography.bodyMedium(c.textMuted)),
                        ],
                      ),
                    )
                  else
                    for (final a in state.activities) _ActivityCard(activity: a),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = activity.type.toUpperCase();

    final (typeIcon, typeColor) = switch (type) {
      'SESSION_COMPLETED' => (LucideIcons.checkCircle, c.accent),
      'MASTERY_ACHIEVED' => (LucideIcons.trophy, c.warning),
      'CHAPTER_STARTED' => (LucideIcons.playCircle, c.textMuted),
      _ => (LucideIcons.activity, c.textMuted),
    };

    final actionLabel = switch (type) {
      'SESSION_COMPLETED' => 'completed a session',
      'MASTERY_ACHIEVED' => 'mastered a topic',
      'CHAPTER_STARTED' => 'started a chapter',
      _ => activity.type,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              activity.studentName.isNotEmpty ? activity.studentName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: activity.studentName,
                      style: AppTypography.bodyMedium(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                  TextSpan(text: ' $actionLabel', style: AppTypography.bodyMedium(c.textSecondary)),
                ])),
                const SizedBox(height: 4),
                if (type == 'SESSION_COMPLETED' && activity.chapter.isNotEmpty)
                  Text('📖 ${activity.chapter}  •  ${activity.correctAnswers}/${activity.questionsAttempted} correct (${(activity.score * 100).round()}%)',
                      style: AppTypography.bodySmall(c.textMuted)),
                if (type == 'MASTERY_ACHIEVED')
                  Text('🎯 ${activity.topic.isNotEmpty ? '${activity.topic} in ' : ''}${activity.chapter}',
                      style: AppTypography.bodySmall(c.textMuted)),
                if (type == 'CHAPTER_STARTED' && activity.chapter.isNotEmpty)
                  Text('📚 Started ${activity.chapter}', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(typeIcon, size: 14, color: typeColor),
              ),
              const SizedBox(height: 4),
              Text(_relativeTime(activity.timestamp), style: AppTypography.mono(c.textMuted, size: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Teacher Student Progress Page ────────────────────────────────────────────

class TeacherStudentPage extends StatelessWidget {
  const TeacherStudentPage({super.key, required this.subjectId, required this.studentId});
  final String subjectId;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final isMock = context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<TeacherStudentCubit>(
      create: (_) => sl<TeacherStudentCubit>()
        ..load(context.read<ProfileCubit>().state.user?.id ?? '', studentId, subjectId, mock: isMock),
      child: _TeacherStudentView(subjectId: subjectId),
    );
  }
}

class _TeacherStudentView extends StatefulWidget {
  const _TeacherStudentView({required this.subjectId});
  final String subjectId;

  @override
  State<_TeacherStudentView> createState() => _TeacherStudentViewState();
}

class _TeacherStudentViewState extends State<_TeacherStudentView> {
  final Set<String> _openChapters = {};

  void _toggle(String id) => setState(() {
        _openChapters.contains(id) ? _openChapters.remove(id) : _openChapters.add(id);
      });

  String _timeAgo(String iso) {
    if (iso.isEmpty) return 'Never';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return d.toLocal().toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<TeacherStudentCubit, TeacherStudentState>(
      builder: (context, state) {
        if (state.status == TLoad.loading) return const SkeletonListLoader();
        final d = state.data;
        final summary = d.subjectSummary;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/teacher/subject/${widget.subjectId}/students'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.arrowLeft, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('Students', style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          d.studentName.isNotEmpty ? d.studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.studentName.isEmpty ? 'Student' : d.studentName,
                                style: AppTypography.h3(c.textPrimary).copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '${d.studentClass}${d.studentEmail.isNotEmpty ? '  •  ${d.studentEmail}' : ''}',
                              style: AppTypography.bodySmall(c.textMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Subject summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: context.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${summary.subjectName} Progress',
                            style: AppTypography.labelLarge(c.textPrimary).copyWith(fontSize: 17)),
                        const SizedBox(height: 16),
                        // 2×2 stat grid (mirrors React's grid-cols-2): two
                        // circular gauges on top, counts below.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MasteryGauge(
                                  value: summary.overallMastery,
                                  size: _GaugeSize.lg,
                                  label: 'Mastery'),
                            ),
                            Expanded(
                              child: _MasteryGauge(
                                  value: summary.overallCoverage,
                                  size: _GaugeSize.lg,
                                  label: 'Coverage'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text('${summary.chaptersStarted}/${summary.totalChapters}',
                                      style: AppTypography.statNumber(c.textPrimary, size: 28)),
                                  Text('Chapters Started', style: AppTypography.mono(c.textMuted, size: 10)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(_timeAgo(summary.lastActive),
                                      style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center),
                                  Text('Last Active', style: AppTypography.mono(c.textMuted, size: 10)),
                                  Text('${summary.totalTimeSpent} min total',
                                      style: AppTypography.bodySmall(c.textMuted), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Icon(LucideIcons.bookOpen, size: 16, color: c.accent),
                      const SizedBox(width: 8),
                      Text('Chapter Progress', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final ch in d.chapters)
                    _ChapterAccordion(
                      chapter: ch,
                      isOpen: _openChapters.contains(ch.chapterId),
                      onToggle: () => _toggle(ch.chapterId),
                    ),

                  const SizedBox(height: 20),

                  if (d.weakTopics.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: context.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.triangleAlert, size: 15, color: c.danger),
                              const SizedBox(width: 8),
                              Text('Weak Topics (${d.weakTopics.length})',
                                  style: AppTypography.labelLarge(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final wt in d.weakTopics)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: c.danger.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(wt.name,
                                            style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                                        Text(wt.chapterName, style: AppTypography.bodySmall(c.textMuted)),
                                      ],
                                    ),
                                  ),
                                  Text('${(wt.masteryScore * 100).round()}%',
                                      style: AppTypography.mono(c.danger, size: 13).copyWith(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (d.recommendations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.accentLight,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.lightbulb, size: 15, color: c.accent),
                              const SizedBox(width: 8),
                              Text('Recommendations',
                                  style: AppTypography.labelLarge(c.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final rec in d.recommendations)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: AppTypography.bodySmall(c.accent)),
                                  Expanded(child: Text(rec, style: AppTypography.bodySmall(c.textPrimary))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChapterAccordion extends StatelessWidget {
  const _ChapterAccordion({required this.chapter, required this.isOpen, required this.onToggle});
  final StudentChapterDetail chapter;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(14),
              color: c.bgCard,
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text('${chapter.order}',
                        style: AppTypography.mono(c.textMuted, size: 12).copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(chapter.name,
                                  style: AppTypography.bodyMedium(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(width: 6),
                            if (chapter.status.isNotEmpty) _StatusBadge(chapter.status),
                          ],
                        ),
                        Text('${chapter.coveragePercentage.round()}% covered  •  ${(chapter.masteryScore * 100).round()}% mastery',
                            style: AppTypography.bodySmall(c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MasteryGauge(value: chapter.masteryScore, size: _GaugeSize.sm),
                  const SizedBox(width: 10),
                  Icon(isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16, color: c.textMuted),
                ],
              ),
            ),
          ),
          if (isOpen && chapter.topics.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(children: [for (final t in chapter.topics) _TopicRow(topic: t)]),
            ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic});
  final StudentTopic topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (stateIcon, stateColor) = switch (topic.state.toUpperCase()) {
      'MASTERED' => (LucideIcons.checkCircle, c.accent),
      'PRACTICING' => (LucideIcons.target, c.textMuted),
      'LEARNING' => (LucideIcons.bookOpen, c.accent),
      'WEAK' => (LucideIcons.triangleAlert, c.danger),
      _ => (LucideIcons.clock, c.textMuted),
    };

    final lastPracticed = topic.lastPracticedAt.isEmpty
        ? 'Never'
        : () {
            final d = DateTime.tryParse(topic.lastPracticedAt);
            return d == null ? topic.lastPracticedAt : d.toLocal().toString().substring(0, 10);
          }();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(stateIcon, size: 16, color: stateColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.name,
                    style: AppTypography.bodySmall(c.textPrimary).copyWith(fontWeight: FontWeight.w500)),
                Text('Last practiced: $lastPracticed', style: AppTypography.bodySmall(c.textMuted)),
              ],
            ),
          ),
          _StatusBadge(topic.state),
          const SizedBox(width: 8),
          Text('${(topic.masteryScore * 100).round()}%',
              style: AppTypography.mono(c.textPrimary, size: 12).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Shared: dropdown pill ─────────────────────────────────────────────────────

class _DropdownPill<T> extends StatelessWidget {
  const _DropdownPill({required this.value, required this.items, required this.onChanged});
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          dropdownColor: c.bgCard,
          icon: Icon(LucideIcons.chevronDown, size: 14, color: c.textMuted),
          style: AppTypography.bodySmall(c.textPrimary),
          items: [for (final it in items) DropdownMenuItem(value: it.$1, child: Text(it.$2))],
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

// ─── AI Generator ─────────────────────────────────────────────────────────────

class TeacherAiGeneratorPage extends StatefulWidget {
  const TeacherAiGeneratorPage({super.key});
  @override
  State<TeacherAiGeneratorPage> createState() => _TeacherAiGeneratorPageState();
}

class _TeacherAiGeneratorPageState extends State<TeacherAiGeneratorPage> {
  final _prompt = TextEditingController();
  String? _answer;
  bool _loading = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_prompt.text.trim().isEmpty) return;
    setState(() { _loading = true; _answer = null; });
    final r = await sl<AiAssistantRepository>().ask(_prompt.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _answer = r.fold((f) => 'Error: ${f.message}', (a) => a);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                  eyebrow: 'TEACHER', title: 'AI', emphasis: 'generator.',
                  subtitle: 'Ask the assistant to generate questions, notes, or explanations.'),
              const SizedBox(height: 20),
              TextField(
                controller: _prompt,
                maxLines: 4,
                style: AppTypography.bodyLarge(c.textPrimary),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.bgCard,
                  hintText: 'e.g. Generate 5 medium MCQs on photosynthesis',
                  hintStyle: AppTypography.bodyMedium(c.textMuted),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c.accent)),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _go,
                style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
                child: Text(_loading ? 'Generating…' : 'Generate'),
              ),
              if (_answer != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: context.cardDecoration(),
                  child: MarkdownBody(data: _answer!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Parent Dashboard ──────────────────────────────────────────────────────────

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ParentCubit>(
      create: (_) => sl<ParentCubit>()..load(),
      child: const _ParentView(),
    );
  }
}

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
