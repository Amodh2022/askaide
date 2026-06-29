import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/btn_spinner.dart';
import '../../../../core/presentation/widgets/confirm_dialog.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/admin_feature.dart';
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

class _AdminView extends StatefulWidget {
  const _AdminView();
  @override
  State<_AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<_AdminView> {
  static const _tabs = [
    'Overview', 'Schools', 'Teachers', 'Students', 'Sections', 'Mappings',
    'Upload', 'Chapters', 'Relations', 'Topics',
  ];
  var _tabIndex = 0;
  final _tabScrollCtl = ScrollController();
  final _tabKeys = List.generate(10, (_) => GlobalKey());

  /// Tabs that scope by the global header school selector. Schools/Teachers
  /// carry their own picker; the rest read the global selection.
  bool get _usesGlobalSchool => false;

  @override
  void dispose() {
    _tabScrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tab = _tabIndex;
    return ExcludeSemantics(
      excluding: true,
      child: Column(
        children: [
          _tabStrip(c),
          Expanded(
            child: SingleChildScrollView(
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
                    Padding(
                      key: ValueKey('panel_${_tabs[tab]}'),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Container(
                        width: double.infinity,
                        decoration: context.cardDecoration(),
                        child: _panel(_tabs[tab]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabStrip(AskAideColors c) {
    final activeTab = _tabIndex;
    return Container(
      height: 49,
      color: c.bgPrimary,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              controller: _tabScrollCtl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = i == activeTab;
                return Center(
                  key: _tabKeys[i],
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _tabIndex = i);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final ctx = _tabKeys[i].currentContext;
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
                        borderRadius: AppRadii.pillR,
                      ),
                      child: Text(_tabs[i],
                          style: AppTypography.bodyMedium(active ? Colors.white : c.textSecondary)),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: c.border),
        ],
      ),
    );
  }

  Widget _panel(String tab) {
    switch (tab) {
      case 'Overview':
        return const AdminOverviewPanel(key: ValueKey('Overview'));
      case 'Schools':
        return const _SchoolsPanel(key: ValueKey('Schools'));
      case 'Teachers':
        return const _TeachersPanel(key: ValueKey('Teachers'));
      case 'Students':
        return const _StudentsPanel(key: ValueKey('Students'));
      case 'Sections':
        return const _SectionsPanel(key: ValueKey('Sections'));
      case 'Mappings':
        return const _MappingsPanel(key: ValueKey('Mappings'));
      case 'Upload':
        return const _UploadPanel(key: ValueKey('Upload'));
      case 'Chapters':
        return const _ChaptersPanel(key: ValueKey('Chapters'));
      case 'Topics':
        return const _TopicsPanel(key: ValueKey('Topics'));
      case 'Relations':
        return const _RelationsPanel(key: ValueKey('Relations'));
      default:
        return const EmptyState(
          key: ValueKey('ComingSoon'),
          icon: Icons.table_chart_outlined,
          title: 'Coming soon',
          hint: 'This section connects to the admin API in a later pass.',
        );
    }
  }

}

/// One editable person row used in the Teachers and Students create forms.
