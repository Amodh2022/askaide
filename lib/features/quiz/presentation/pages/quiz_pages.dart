import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/shimmer.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/quiz_models.dart';
import '../quiz_cubits.dart';

part 'quiz_pages_parts/list_part.dart';
part 'quiz_pages_parts/attempt_part.dart';
part 'quiz_pages_parts/result_part.dart';
part 'quiz_pages_parts/history_part.dart';

/// `/quizzes` — the student's available-quiz list, loaded live.
class StudentQuizListPage extends StatelessWidget {
  const StudentQuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        context.read<ProfileCubit>().state.role?.isSuperAdmin ?? false;
    return BlocProvider<QuizListCubit>(
      create: (_) {
        final cubit = sl<QuizListCubit>();
        if (!isSuperAdmin) cubit.loadAvailable(page: 1, limit: 12);
        return cubit;
      },
      child: _QuizListView(isMockMode: isSuperAdmin),
    );
  }
}


/// `/quiz/:quizId/attempt/:attemptId` — the timed quiz-taking screen. The
/// attempt is loaded via the resume-or-create `/start` endpoint (see [build]);
/// the URL's attemptId is informational only.
class QuizAttemptPage extends StatelessWidget {
  const QuizAttemptPage(
      {super.key, required this.quizId, required this.attemptId});
  final String quizId;
  final String attemptId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizAttemptCubit>(
      // The `/start` endpoint is resume-or-create: it returns a fresh attempt
      // for an available quiz, or the existing in-progress attempt (with its
      // saved answers) when one exists. This mirrors the frontend, which always
      // calls startQuizAttempt regardless of the URL's attemptId.
      create: (_) => sl<QuizAttemptCubit>()..start(quizId),
      child: const _QuizAttemptView(),
    );
  }
}

/// `/quiz/result/:attemptId` — graded result + answer review.
class QuizResultPage extends StatelessWidget {
  const QuizResultPage({super.key, required this.attemptId});
  final String attemptId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizResultCubit>(
      create: (_) => sl<QuizResultCubit>()..load(attemptId),
      child: const _QuizResultView(),
    );
  }
}

/// `/quiz/history` — past attempts, loaded live.
class QuizHistoryPage extends StatelessWidget {
  const QuizHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizListCubit>(
      create: (_) => sl<QuizListCubit>()..loadHistory(page: 1, limit: 10),
      child: const _QuizHistoryView(),
    );
  }
}
