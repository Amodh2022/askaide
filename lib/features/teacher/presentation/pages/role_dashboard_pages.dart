import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../parent/parent_feature.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/teacher_feature.dart';
import '../cubit/chapter_accordion_cubit.dart';
import '../cubit/student_filter_cubit.dart';
import '../cubit/teacher_ai_generator_cubit.dart';

part 'role_dashboard_pages_parts/shared.dart';
part 'role_dashboard_pages_parts/home_panel.dart';
part 'role_dashboard_pages_parts/subject_panel.dart';
part 'role_dashboard_pages_parts/students_panel.dart';
part 'role_dashboard_pages_parts/chapter_panel.dart';
part 'role_dashboard_pages_parts/weak_topics_panel.dart';
part 'role_dashboard_pages_parts/activity_panel.dart';
part 'role_dashboard_pages_parts/student_panel.dart';
part 'role_dashboard_pages_parts/ai_generator_panel.dart';
part 'role_dashboard_pages_parts/parent_panel.dart';

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

// ─── AI Generator ─────────────────────────────────────────────────────────────

class TeacherAiGeneratorPage extends StatelessWidget {
  const TeacherAiGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherAiGeneratorCubit>(
      create: (_) => sl<TeacherAiGeneratorCubit>(),
      child: const _TeacherAiGeneratorView(),
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
