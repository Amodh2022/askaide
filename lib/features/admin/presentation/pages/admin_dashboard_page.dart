import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/confirm_dialog.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/validation/field_validators.dart';
import '../../data/admin_feature.dart';
import '../cubit/admin_picker_search_cubit.dart';
import '../cubit/admin_tab_cubit.dart';
import '../cubit/chapters_panel_cubit.dart';
import '../cubit/curriculum_panel_cubit.dart';
import '../cubit/mappings_panel_cubit.dart';
import '../cubit/relations_cubit.dart';
import '../cubit/schools_panel_cubit.dart';
import '../cubit/sections_panel_cubit.dart';
import '../cubit/students_panel_cubit.dart';
import '../cubit/teachers_panel_cubit.dart';
import '../cubit/topics_panel_cubit.dart';
import '../cubit/upload_chapter_cubit.dart';
import '../widgets/admin_overview_panel.dart';

part 'panels/picker.dart';
part 'panels/shared.dart';
part 'panels/upload_panel.dart';
part 'panels/curriculum_panel.dart';
part 'panels/chapters_panel.dart';
part 'panels/topics_panel.dart';
part 'panels/teachers_panel.dart';
part 'panels/students_panel.dart';
part 'panels/schools_panel.dart';
part 'panels/sections_panel.dart';
part 'panels/relations_panel.dart';
part 'panels/mappings_panel.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminCubit>(
      create: (_) => sl<AdminCubit>()..init(),
      child: const _AdminView(),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView();

  static const _tabs = [
    'Overview', 'Schools', 'Teachers', 'Students', 'Sections', 'Mappings',
    'Upload', 'Chapters', 'Relations', 'Topics',
  ];

  /// Tabs that scope by the global header school selector. Schools/Teachers
  /// carry their own picker; the rest read the global selection.
  bool get _usesGlobalSchool => false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminTabCubit>(
      create: (_) => sl<AdminTabCubit>(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;
    final tabCubit = context.read<AdminTabCubit>();
    final selected = context.watch<AdminTabCubit>().state;
    // NestedScrollView lets the header (title + school selector) scroll away
    // while the tab chips pin to the top; each panel's own list scrolls below.
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: PageHeader(
                  eyebrow: 'ADMIN PANEL',
                  title: 'Manage your',
                  emphasis: 'institution.',
                  subtitle: 'Schools, teachers, students, and content — all in one place.',
                ),
              ),
              BlocBuilder<AdminCubit, AdminState>(
                buildWhen: (p, n) =>
                    p.schools != n.schools || p.selectedSchoolId != n.selectedSchoolId,
                builder: (context, state) {
                  // Tabs with their own school picker (Schools/Teachers) hide the
                  // global one to avoid a duplicate selector.
                  if (!_usesGlobalSchool || state.schools.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _PickerField(
                      label: 'School',
                      hint: 'Select school…',
                      items: state.schools
                          .map((s) => AdminRecord(id: s.id, name: s.name))
                          .toList(),
                      selectedId: state.selectedSchoolId,
                      onChanged: (v) => context.read<AdminCubit>().selectSchool(v),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedTabBar(height: 57, child: _tabStrip(c, tabCubit, selected)),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Container(
          width: double.infinity,
          decoration: context.cardDecoration(),
          child: _panel(_tabs[selected]),
        ),
      ),
    );
  }

  /// The horizontal pill tab strip; pinned to the top via [_PinnedTabBar].
  Widget _tabStrip(AskAideColors c, AdminTabCubit tabCubit, int selected) {
    return Container(
      color: c.bgPrimary,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              controller: tabCubit.scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = i == selected;
                return Center(
                  key: tabCubit.tabKeys[i],
                  child: GestureDetector(
                    onTap: () {
                      tabCubit.select(i);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final ctx = tabCubit.tabKeys[i].currentContext;
                        if (ctx != null) {
                          Scrollable.ensureVisible(ctx,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              alignmentPolicy:
                                  ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? c.accent : c.bgCard,
                        border: Border.all(color: active ? c.accent : c.border),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(_tabs[i],
                          style: AppTypography.bodyMedium(active ? Colors.white : c.textSecondary)),
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Divider(height: 1, color: c.border),
        ],
      ),
    );
  }

  Widget _panel(String tab) {
    switch (tab) {
      case 'Overview':
        return const AdminOverviewPanel();
      case 'Schools':
        return const _SchoolsPanel();
      case 'Teachers':
        return const _TeachersPanel();
      case 'Students':
        return const _StudentsPanel();
      case 'Sections':
        return const _SectionsPanel();
      case 'Mappings':
        return const _MappingsPanel();
      case 'Upload':
        return const _UploadPanel();
      case 'Chapters':
        return const _ChaptersPanel();
      case 'Topics':
        return const _TopicsPanel();
      case 'Relations':
        return const _RelationsPanel();
      default:
        return const EmptyState(
          icon: Icons.table_chart_outlined,
          title: 'Coming soon',
          hint: 'This section connects to the admin API in a later pass.',
        );
    }
  }

}

/// One editable person row used in the Teachers and Students create forms.
