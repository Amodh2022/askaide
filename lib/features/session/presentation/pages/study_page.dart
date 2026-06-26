import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../bloc/session_bloc.dart';
import '../widgets/practice_panel.dart';
import '../widgets/study_config_panel.dart';
import '../widgets/study_history_sidebar.dart';
import '../widgets/user_answers_panel.dart';

/// `/study` — the core practice hub. Desktop shows the study-history rail beside
/// a main card; mobile shows a header (with a Sessions drawer) above the panel.
/// The visible panel (config / practice / review) is driven by SessionBloc.
class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  /// The user id we've already loaded server history for, so the profile
  /// listener doesn't refetch on every emit.
  String? _historyUserId;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<SessionBloc>();
    final userId = context.read<ProfileCubit>().state.user?.id ?? '';
    if (userId.isNotEmpty) _historyUserId = userId;
    bloc.add(SessionInitialised(userId: userId));
    if (bloc.state.classes.isEmpty) bloc.add(const ClassesRequested());
  }

  Widget _panel(SessionPanel panel) {
    switch (panel) {
      case SessionPanel.practice:
        return const PracticePanel();
      case SessionPanel.review:
        return const UserAnswersPanel();
      case SessionPanel.config:
        return const StudyConfigPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocListener<ProfileCubit, ProfileState>(
      // The profile loads asynchronously; once the user id is known, fetch the
      // server-side session history (once per user).
      listenWhen: (p, n) => p.user?.id != n.user?.id,
      listener: (context, profile) {
        final userId = profile.user?.id ?? '';
        if (userId.isNotEmpty && userId != _historyUserId) {
          _historyUserId = userId;
          context.read<SessionBloc>().add(SessionInitialised(userId: userId));
        }
      },
      child: BlocBuilder<SessionBloc, SessionState>(
        buildWhen: (p, n) => p.panel != n.panel,
        builder: (context, state) {
        final mainCard = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.bgCard,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: _panel(state.panel),
        );

        if (context.isDesktop) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StudyHistorySidebar(),
                const SizedBox(width: 16),
                Expanded(child: mainCard),
              ],
            ),
          );
        }

        // Mobile: header + panel; history opens in a drawer.
        // The header (and its Sessions button) is hidden during practice so the
        // student gets a distraction-free full-screen question view.
        return Scaffold(
          backgroundColor: c.bgPrimary,
          drawer: Drawer(
            child: SafeArea(
              child: StudyHistorySidebar(onSelect: () => Navigator.of(context).pop()),
            ),
          ),
          body: Column(
            children: [
              if (state.panel != SessionPanel.practice)
                Builder(
                  builder: (context) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('AskAide', style: AppTypography.h4(c.textPrimary).copyWith(fontSize: 18)),
                        OutlinedButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: c.border),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Sessions', style: AppTypography.bodySmall(c.textPrimary)),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(child: _panel(state.panel)),
            ],
          ),
        );
        },
      ),
    );
  }
}
