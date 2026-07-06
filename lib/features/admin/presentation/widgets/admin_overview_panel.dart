import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_helpers.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/state_visuals.dart';
import '../../data/admin_feature.dart';
import '../cubit/admin_overview_cubit.dart';

/// Shimmer skeleton mirroring the admin overview's metric cards + charts layout.
class _AdminOverviewSkeleton extends StatelessWidget {
  const _AdminOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Toolbar row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              4,
              (_) => Container(
                width: 100,
                height: 36,
                decoration: BoxDecoration(
                  color: c.bgCard,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Section label
          const SkeletonBox(width: 140, height: 11),
          const SizedBox(height: 8),
          const SkeletonBox(width: 200, height: 10),
          const SizedBox(height: 12),
          // Metric card grid
          LayoutBuilder(
            builder: (context, cons) {
              final cols = (cons.maxWidth / 150).floor().clamp(1, 6);
              final gap = 8.0;
              final rows = <Widget>[];
              for (var i = 0; i < 6; i += cols) {
                rows.add(Padding(
                  padding: EdgeInsets.only(top: rows.isEmpty ? 0 : gap),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      cols,
                      (j) {
                        if (i + j >= 6) return const SizedBox.shrink();
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: j > 0 ? gap : 0),
                            child: const SkeletonAdminMetricCard(),
                          ),
                        );
                      },
                    ),
                  ),
                ));
              }
              return Column(children: rows);
            },
          ),
          const SizedBox(height: 24),
          // Section label
          const SkeletonBox(width: 120, height: 11),
          const SizedBox(height: 8),
          const SkeletonBox(width: 180, height: 10),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: _ > 0 ? 8 : 0),
                  child: const SkeletonAdminMetricCard(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Chart boxes row (2)
          Row(
            children: List.generate(
              2,
              (_) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: _ > 0 ? 12 : 0),
                  child: const SkeletonChartBox(height: 220),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Section label
          const SkeletonBox(width: 130, height: 11),
          const SizedBox(height: 8),
          const SkeletonBox(width: 200, height: 10),
          const SizedBox(height: 10),
          // More stats rows
          Row(
            children: List.generate(
              5,
              (_) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: _ > 0 ? 8 : 0),
                  child: const SkeletonAdminMetricCard(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SkeletonChartBox(height: 200),
        ],
      ),
    );
  }
}

/// `/admin` → **Overview** tab. SuperAdmin metrics dashboard mirroring React
/// `AdminOverview`: platform KPIs + Users / Content / Question-jobs /
/// Engagement sections with real charts (donut/bar/line/stacked) and the
/// coverage-by-class & recent-failures tables. Date range + class/subject
/// filters drive the filtered endpoints.
class AdminOverviewPanel extends StatelessWidget {
  const AdminOverviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminOverviewCubit>(
      create: (_) => sl<AdminOverviewCubit>()..load(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<AdminOverviewCubit>();
    final state = context.watch<AdminOverviewCubit>().state;
    if (state.loading) return const _AdminOverviewSkeleton();
    if (state.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load metrics',
              hint: 'Check your connection and retry.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: cubit.load,
              style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _toolbar(context, c, cubit, state),
        const SizedBox(height: 16),
        _glance(context, c, state),
        _section(c, 'USERS & GROWTH', 'Accounts, roles, and signups', _usersBody(context, c, state)),
        _section(c, 'CONTENT & CATALOG', 'Curriculum coverage and question bank',
            _contentBody(context, c, state)),
        _section(c, 'QUESTION GENERATION HEALTH', 'AI generation job success and failures',
            _jobsBody(context, c, state)),
        _section(c, 'ENGAGEMENT & LEARNING', 'Activity, mastery, and feedback',
            _engagementBody(context, c, state)),
      ],
    );
  }

  // ── Toolbar ──
  Widget _toolbar(
      BuildContext context, AskAideColors c, AdminOverviewCubit cubit, AdminOverviewState state) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: state.range,
            );
            if (picked != null) cubit.setRange(picked);
          },
          icon: const Icon(Icons.date_range, size: 16),
          label: Text(
              '${AdminOverviewCubit.fmtDate(state.range.start)} → ${AdminOverviewCubit.fmtDate(state.range.end)}',
              style: AppTypography.bodySmall(c.textSecondary)),
        ),
        for (final n in const [7, 30, 90])
          OutlinedButton(
            onPressed: () => cubit.quickRange(n),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: Text('${n}D', style: AppTypography.mono(c.textMuted, size: 11)),
          ),
        _filterDropdown(context, 'All classes', state.classId,
            context.watch<AdminCubit>().state.classes, cubit.selectClass),
        _filterDropdown(
            context,
            state.classId == null ? 'Select class first' : 'All subjects',
            state.subjectId,
            state.subjects,
            state.classId == null ? null : cubit.selectSubject),
        IconButton(
          tooltip: 'Refresh',
          onPressed: cubit.load,
          icon: Icon(Icons.refresh, size: 18, color: c.accent),
        ),
        if (state.updatedAt != null)
          Text('Updated ${state.updatedAt!.format(context)}', style: AppTypography.mono(c.textMuted, size: 10)),
      ],
    );
  }

  Widget _filterDropdown(BuildContext context, String hint, String? value, List<AdminRecord> items,
      ValueChanged<String?>? onChanged) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(hint, style: AppTypography.bodySmall(c.textMuted)),
          dropdownColor: c.bgCard,
          isDense: true,
          style: AppTypography.bodySmall(c.textPrimary),
          onChanged: onChanged,
          items: [
            DropdownMenuItem(value: null, child: Text(hint)),
            for (final it in items)
              DropdownMenuItem(value: it.id, child: Text(it.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  // ── Platform at a glance ──
  Widget _glance(BuildContext context, AskAideColors c, AdminOverviewState state) {
    final o = state.overview ?? const {};
    final totalChapters = o.intval(['totalChapters']);
    return _cardGrid(context, [
      _Stat('Total Users', '${o.intval(['totalUsers'])}',
          sub: '${o.intval(['totalStudents'])} students · ${o.intval(['totalTeachers'])} teachers'),
      _Stat('Schools', '${o.intval(['totalSchools'])}'),
      _Stat('Sessions', '${o.intval(['totalSessions'])}', sub: '${o.intval(['totalQuestionsAnswered'])} answers'),
      _Stat('Questions', '${o.intval(['totalQuestions'])}'),
      _Stat('Chapters', '$totalChapters'),
      _Stat('Content Coverage', '${o.intval(['contentCoveragePct'])}%',
          sub: '${o.intval(['chaptersWithQuestions'])}/$totalChapters chapters'),
    ], label: 'PLATFORM AT A GLANCE');
  }

  // ── Users & Growth ──
  Widget _usersBody(BuildContext context, AskAideColors c, AdminOverviewState state) {
    final u = state.users ?? const {};
    final byRole = (u['byRole'] as List?) ?? const [];
    final status = (u['status'] as Map?) ?? const {};
    final signups = (u['signupsByDay'] as List?) ?? const [];
    final perSchool = (u['studentsPerSchool'] as List?) ?? const [];
    final totalUsers = byRole.fold<int>(0, (s, r) => s + (r is Map ? r.intval(['count']) : 0));

    final roleSlices = [
      for (var i = 0; i < byRole.length; i++)
        if (byRole[i] is Map)
          _Slice((byRole[i] as Map).str(['role'], 'role'),
              (byRole[i] as Map).intval(['count']).toDouble(), _palette[i % _palette.length]),
    ];
    final schoolBars = [
      for (final s in perSchool.whereType<Map>())
        _Bar(s.str(['schoolName'], 'School'), s.intval(['students']).toDouble()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardGrid(context, [
          _Stat('Total Users', '$totalUsers'),
          _Stat('Active Users', '${status.intval(['active'])}'),
          _Stat('Approved Users', '${status.intval(['approved'])}'),
          _Stat('Schools', '${perSchool.length}'),
        ]),
        const SizedBox(height: 12),
        _chartRow(c, [
          _chartBox(c, 'New signups', _lineChart(c, [
            _Series('Signups', [for (final d in signups.whereType<Map>()) d.intval(['count']).toDouble()], c.accent),
          ], [for (final d in signups.whereType<Map>()) _mmdd(d.str(['date']))], area: true)),
          _chartBox(c, 'Users by role', _donut(c, roleSlices)),
        ]),
        if (schoolBars.isNotEmpty) ...[
          const SizedBox(height: 12),
          _chartBox(c, 'Students per school', _barChart(c, schoolBars, c.accent)),
        ],
      ],
    );
  }

  // ── Content & Catalog ──
  Widget _contentBody(BuildContext context, AskAideColors c, AdminOverviewState state) {
    final ct = state.content ?? const {};
    final counts = (ct['counts'] as Map?) ?? const {};
    final coverage = (ct['coverage'] as Map?) ?? const {};
    final bank = (ct['questionBank'] as List?) ?? const [];
    final byClass = (ct['coverageByClass'] as List?) ?? const [];
    final pct = coverage.intval(['coveragePct']);

    // Pivot question bank into difficulty × type for the stacked bar.
    final types = <String>{for (final q in bank.whereType<Map>()) q.str(['questionType'], 'other')}.toList();
    final pivot = <String, Map<String, int>>{};
    for (final q in bank.whereType<Map>()) {
      final d = q.str(['difficulty'], 'unknown');
      (pivot[d] ??= {})[q.str(['questionType'], 'other')] =
          (pivot[d]?[q.str(['questionType'], 'other')] ?? 0) + q.intval(['count']);
    }
    const order = ['easy', 'medium', 'hard'];
    final difficulties = [
      ...order.where(pivot.containsKey),
      ...pivot.keys.where((d) => !order.contains(d)),
    ];
    final diffSlices = [
      for (final d in difficulties)
        _Slice(d, (pivot[d]?.values.fold<int>(0, (s, v) => s + v) ?? 0).toDouble(),
            DifficultyVisuals.colorFor(d, c)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardGrid(context, [
          _Stat('Classes', '${counts.intval(['classes'])}'),
          _Stat('Subjects', '${counts.intval(['subjects'])}'),
          _Stat('Chapters', '${counts.intval(['chapters'])}'),
          _Stat('Topics', '${counts.intval(['topics'])}'),
          _Stat('Total Questions', '${ct.intval(['totalQuestions'])}'),
        ]),
        const SizedBox(height: 12),
        _chartBox(
          c,
          'Chapter coverage',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$pct%', style: AppTypography.statNumber(c.accent, size: 36)),
              Text('${coverage.intval(['chaptersWithQuestions'])} of ${coverage.intval(['totalChapters'])} chapters have questions',
                  style: AppTypography.bodySmall(c.textMuted)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (pct.clamp(0, 100)) / 100,
                  minHeight: 10,
                  backgroundColor: c.border,
                  valueColor: AlwaysStoppedAnimation(_coverageColor(pct)),
                ),
              ),
            ],
          ),
        ),
        if (byClass.isNotEmpty) ...[
          const SizedBox(height: 12),
          _chartBox(c, 'Coverage by class', _coverageTable(c, byClass)),
        ],
        const SizedBox(height: 12),
        _chartRow(c, [
          _chartBox(c, 'Question bank by difficulty & type',
              _stackedBar(c, difficulties, types, pivot)),
          _chartBox(c, 'Questions by difficulty', _donut(c, diffSlices)),
        ]),
      ],
    );
  }

  // ── Question Generation Health ──
  Widget _jobsBody(BuildContext context, AskAideColors c, AdminOverviewState state) {
    final j = state.jobs ?? const {};
    final byStatus = (j['byStatus'] as Map?) ?? const {};
    final failures = (j['recentFailures'] as List?) ?? const [];
    final failPct = j.intval(['failureRatePct']);
    final high = failPct > 20;
    final statusSlices = [
      _Slice('completed', byStatus.intval(['completed']).toDouble(), _green),
      _Slice('failed', byStatus.intval(['failed']).toDouble(), _red),
      _Slice('processing', byStatus.intval(['processing']).toDouble(), _amber),
    ].where((s) => s.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardGrid(context, [
          _Stat('Total Jobs', '${j.intval(['total'])}'),
          _Stat('Completed', '${byStatus.intval(['completed'])}', color: _green),
          _Stat('Failed', '${byStatus.intval(['failed'])}', color: _red),
          _Stat('Failure Rate', '$failPct%',
              color: high ? _red : null, sub: high ? 'Above 20% threshold' : null),
        ]),
        const SizedBox(height: 12),
        _chartBox(c, 'Job status', _donut(c, statusSlices)),
        const SizedBox(height: 12),
        _chartBox(c, 'Recent failures', _failuresTable(c, failures)),
      ],
    );
  }

  // ── Engagement & Learning ──
  Widget _engagementBody(BuildContext context, AskAideColors c, AdminOverviewState state) {
    final e = state.engagement ?? const {};
    final active = (e['activeLearners'] as Map?) ?? const {};
    final accuracy = (e['accuracy'] as Map?) ?? const {};
    final streaks = (e['streaks'] as Map?) ?? const {};
    final daily = (e['dailyChallenge'] as Map?) ?? const {};
    final quizzes = (e['quizzes'] as Map?) ?? const {};
    final mastery = (e['masteryDistribution'] as List?) ?? const [];
    final feedback = (e['feedback'] as Map?) ?? const {};
    final sentiment = (feedback['sentiment'] as Map?) ?? const {};
    final sessions = (e['sessionsByDay'] as List?) ?? const [];
    final answers = (e['answersByDay'] as List?) ?? const [];

    // Merge sessions + answers by date for the activity line chart.
    final dates = <String>{
      for (final d in sessions.whereType<Map>()) d.str(['date']),
      for (final d in answers.whereType<Map>()) d.str(['date']),
    }.toList()
      ..sort();
    final sessionMap = {for (final d in sessions.whereType<Map>()) d.str(['date']): d.intval(['count'])};
    final answerMap = {for (final d in answers.whereType<Map>()) d.str(['date']): d.intval(['count'])};

    final masterySegs = [
      for (final m in mastery.whereType<Map>())
        _Slice(m.str(['state'], 'state'), m.intval(['count']).toDouble(),
            MasteryVisuals.colorFor(m.str(['state']), c)),
    ];
    final sentSlices = [
      for (final k in const ['positive', 'neutral', 'negative'])
        if (sentiment.intval([k]) > 0)
          _Slice(k, sentiment.intval([k]).toDouble(),
              k == 'positive' ? _green : (k == 'neutral' ? _amber : _red)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardGrid(context, [
          _Stat('Daily Active', '${active.intval(['dau'])}'),
          _Stat('Weekly Active', '${active.intval(['wau'])}'),
          _Stat('Monthly Active', '${active.intval(['mau'])}'),
          _Stat('Overall Accuracy', '${accuracy.intval(['accuracyPct'])}%',
              sub: '${accuracy.intval(['correct'])} / ${accuracy.intval(['total'])} correct'),
          _Stat('Daily Challenge', '${daily.intval(['completionPct'])}%', sub: 'completed'),
          _Stat('Quiz Pass Rate', '${quizzes.intval(['passRatePct'])}%'),
          _Stat('Active Streaks', '${streaks.intval(['activeStreaks'])}',
              sub: 'longest ${streaks.intval(['maxLongest'])}d · avg ${streaks.intval(['avgCurrent'])}'),
        ]),
        const SizedBox(height: 12),
        _chartBox(c, 'Activity (sessions & answers)', _lineChart(c, [
          _Series('Sessions', [for (final d in dates) (sessionMap[d] ?? 0).toDouble()], c.accent),
          _Series('Answers', [for (final d in dates) (answerMap[d] ?? 0).toDouble()], _green),
        ], [for (final d in dates) _mmdd(d)], legend: true)),
        if (masterySegs.isNotEmpty) ...[
          const SizedBox(height: 12),
          _chartBox(c, 'Topic mastery distribution', _stackedRow(c, masterySegs)),
        ],
        if (sentSlices.isNotEmpty) ...[
          const SizedBox(height: 12),
          _chartBox(
            c,
            'Session feedback',
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _donut(c, sentSlices),
              if (feedback.intval(['npsResponses']) > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Avg NPS ${feedback.dbl(['avgNps']).toStringAsFixed(1)} · ${feedback.intval(['npsResponses'])} responses',
                      style: AppTypography.bodySmall(c.textMuted)),
                ),
            ]),
          ),
        ],
      ],
    );
  }

  // ── Chart primitives ──────────────────────────────────────────────────

  Widget _donut(AskAideColors c, List<_Slice> slices) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return _noData(c);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 34,
            sections: [
              for (final s in slices)
                PieChartSectionData(value: s.value, color: s.color, radius: 22, showTitle: false),
            ],
          )),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [for (final s in slices) _legendRow(c, s)],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(AskAideColors c, _Slice s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Expanded(child: Text(s.label, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall(c.textSecondary))),
          Text('${s.value.toInt()}', style: AppTypography.bodySmall(c.textPrimary)),
        ]),
      );

  Widget _barChart(AskAideColors c, List<_Bar> bars, Color color) {
    if (bars.isEmpty) return _noData(c);
    final maxY = bars.map((b) => b.value).fold<double>(0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 180,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(c, [for (final b in bars) b.label], showLeft: true),
        barGroups: [
          for (var i = 0; i < bars.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: bars[i].value,
                color: color,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ]),
        ],
      )),
    );
  }

  Widget _stackedBar(
      AskAideColors c, List<String> categories, List<String> types, Map<String, Map<String, int>> data) {
    if (categories.isEmpty) return _noData(c);
    double maxY = 0;
    for (final cat in categories) {
      final sum = types.fold<double>(0, (s, t) => s + (data[cat]?[t] ?? 0).toDouble());
      if (sum > maxY) maxY = sum;
    }
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY <= 0 ? 1 : maxY * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: _titles(c, categories, showLeft: true),
            barGroups: [
              for (var i = 0; i < categories.length; i++)
                _stackGroup(i, categories[i], types, data),
            ],
          )),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 4, children: [
          for (var ti = 0; ti < types.length; ti++)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _palette[ti % _palette.length], borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text(types[ti], style: AppTypography.bodySmall(c.textMuted)),
            ]),
        ]),
      ],
    );
  }

  BarChartGroupData _stackGroup(int i, String cat, List<String> types, Map<String, Map<String, int>> data) {
    double running = 0;
    final stack = <BarChartRodStackItem>[];
    for (var ti = 0; ti < types.length; ti++) {
      final v = (data[cat]?[types[ti]] ?? 0).toDouble();
      if (v > 0) {
        stack.add(BarChartRodStackItem(running, running + v, _palette[ti % _palette.length]));
        running += v;
      }
    }
    return BarChartGroupData(x: i, barRods: [
      BarChartRodData(toY: running, rodStackItems: stack, width: 18, borderRadius: BorderRadius.zero),
    ]);
  }

  Widget _lineChart(AskAideColors c, List<_Series> series, List<String> labels,
      {bool area = false, bool legend = false}) {
    if (series.isEmpty || series.every((s) => s.values.isEmpty)) return _noData(c);
    final maxY = series.expand((s) => s.values).fold<double>(0, (m, v) => v > m ? v : m);
    final step = (labels.length / 4).ceil();
    return Column(
      children: [
        SizedBox(
          height: 180,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: maxY <= 0 ? 1 : maxY * 1.2,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: c.borderSubtle, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                  return LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    TextStyle(
                      color: s.bar.color ?? Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  );
                }).toList(),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) =>
                      Text(v.toInt().toString(), style: AppTypography.mono(c.textMuted, size: 8)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (step < 1 ? 1 : step).toDouble(),
                  reservedSize: 18,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Text(labels[i], style: AppTypography.mono(c.textMuted, size: 8));
                  },
                ),
              ),
            ),
            lineBarsData: [
              for (final s in series)
                LineChartBarData(
                  spots: [for (var i = 0; i < s.values.length; i++) FlSpot(i.toDouble(), s.values[i])],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: s.color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: area
                      ? BarAreaData(show: true, color: s.color.withValues(alpha: 0.15))
                      : BarAreaData(show: false),
                ),
            ],
          )),
        ),
        if (legend) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 12, children: [
            for (final s in series)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Text(s.label, style: AppTypography.bodySmall(c.textMuted)),
              ]),
          ]),
        ],
      ],
    );
  }

  /// Single horizontal stacked bar (mastery distribution).
  Widget _stackedRow(AskAideColors c, List<_Slice> segs) {
    final total = segs.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return _noData(c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 22,
            child: Row(children: [
              for (final s in segs)
                if (s.value > 0) Expanded(flex: (s.value * 100).round(), child: Container(color: s.color)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 4, children: [for (final s in segs) _legendInline(c, s)]),
      ],
    );
  }

  Widget _legendInline(AskAideColors c, _Slice s) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text('${s.label} ${s.value.toInt()}', style: AppTypography.bodySmall(c.textMuted)),
      ]);

  FlTitlesData _titles(AskAideColors c, List<String> labels, {bool showLeft = false}) => FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showLeft,
            reservedSize: 28,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: AppTypography.mono(c.textMuted, size: 8)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= labels.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(c.textMuted, size: 8)),
              );
            },
          ),
        ),
      );

  Widget _coverageTable(AskAideColors c, List<dynamic> rows) {
    return Column(
      children: [
        for (final r in rows.whereType<Map>())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(
                  width: 120,
                  child: Text(r.str(['className', 'name'], 'Class'),
                      overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall(c.textPrimary))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (r.intval(['coveragePct']).clamp(0, 100)) / 100,
                    minHeight: 8,
                    backgroundColor: c.border,
                    valueColor: AlwaysStoppedAnimation(_coverageColor(r.intval(['coveragePct']))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                  width: 86,
                  child: Text('${r.intval(['chaptersWithQuestions'])}/${r.intval(['totalChapters'])} · ${r.intval(['coveragePct'])}%',
                      textAlign: TextAlign.right, style: AppTypography.bodySmall(c.textMuted))),
            ]),
          ),
      ],
    );
  }

  Widget _failuresTable(AskAideColors c, List<dynamic> failures) {
    if (failures.isEmpty) {
      return Text('All question generation jobs are running smoothly.',
          style: AppTypography.bodySmall(c.textMuted));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: AppTypography.mono(c.textMuted, size: 10),
        columns: const [
          DataColumn(label: Text('CHAPTER')),
          DataColumn(label: Text('TYPE')),
          DataColumn(label: Text('DIFFICULTY')),
          DataColumn(label: Text('ERROR')),
        ],
        rows: [
          for (final f in failures.whereType<Map>())
            DataRow(cells: [
              DataCell(Text(f.str(['chapterName', 'name'], '—'), style: AppTypography.bodySmall(c.textPrimary))),
              DataCell(Text(f.str(['questionType', 'type'], '—'), style: AppTypography.bodySmall(c.textSecondary))),
              DataCell(Text(f.str(['difficulty'], '—'), style: AppTypography.bodySmall(c.textSecondary))),
              DataCell(SizedBox(
                  width: 220,
                  child: Text(_truncate(f.str(['error', 'message'])), maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(c.danger)))),
            ]),
        ],
      ),
    );
  }

  // ── Shared building blocks ──
  Widget _section(AskAideColors c, String title, String subtitle, Widget body) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.mono(c.accent, size: 11)),
            Text(subtitle, style: AppTypography.bodySmall(c.textMuted)),
            const SizedBox(height: 12),
            body,
          ],
        ),
      );

  /// Lays out chart boxes 2-up on wide screens, stacked on narrow.
  Widget _chartRow(AskAideColors c, List<Widget> boxes) {
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < 560) {
        return Column(children: [
          for (var i = 0; i < boxes.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            boxes[i],
          ],
        ]);
      }
      final w = (box.maxWidth - 12) / 2;
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < boxes.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              SizedBox(width: w, child: boxes[i]),
            ],
          ],
        ),
      );
    });
  }

  Widget _chartBox(AskAideColors c, String title, Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.bgCard,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.bodyMedium(c.textSecondary)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  Widget _noData(AskAideColors c) => SizedBox(
        height: 80,
        child: Center(child: Text('No data', style: AppTypography.bodySmall(c.textMuted))),
      );

  Widget _cardGrid(BuildContext context, List<_Stat> stats, {String? label}) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: AppTypography.mono(c.textMuted, size: 11)),
          const SizedBox(height: 8),
        ],
        LayoutBuilder(builder: (context, box) {
          final cols = (box.maxWidth / 150).floor().clamp(1, stats.length);
          const gap = 8.0;
          final rows = <Widget>[];
          for (var i = 0; i < stats.length; i += cols) {
            final end = (i + cols) > stats.length ? stats.length : i + cols;
            final slice = stats.sublist(i, end);
            rows.add(Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
              // IntrinsicHeight + stretch makes every card in a row equal height.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < cols; j++) ...[
                      if (j > 0) const SizedBox(width: gap),
                      Expanded(
                        child: j < slice.length
                            ? _statCard(c, slice[j])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ));
          }
          return Column(children: rows);
        }),
      ],
    );
  }

  Widget _statCard(AskAideColors c, _Stat s) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bgCard,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.label.toUpperCase(), style: AppTypography.mono(c.textMuted, size: 10)),
            const SizedBox(height: 6),
            Text(s.value, style: AppTypography.h4(s.color ?? c.textPrimary)),
            if (s.sub != null) Text(s.sub!, style: AppTypography.bodySmall(c.textMuted)),
          ],
        ),
      );

  Color _coverageColor(int pct) => pct < 20 ? _red : (pct < 60 ? _amber : _green);

  static String _mmdd(String iso) => iso.length >= 10 ? iso.substring(5) : iso;
  static String _truncate(String s, [int max = 80]) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}

// React PALETTE: indigo, green, amber, red, cyan, purple.
const _palette = [
  Color(0xFF6366F1),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF06B6D4),
  Color(0xFF8B5CF6),
];
const _green = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

class _Stat {
  _Stat(this.label, this.value, {this.sub, this.color});
  final String label;
  final String value;
  final String? sub;
  final Color? color;
}

class _Slice {
  _Slice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class _Bar {
  _Bar(this.label, this.value);
  final String label;
  final double value;
}

class _Series {
  _Series(this.label, this.values, this.color);
  final String label;
  final List<double> values;
  final Color color;
}
