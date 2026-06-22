import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/domain/entities/account_type.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/auth/domain/entities/signup_data.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/update_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/progress_page.dart';
import '../../features/marketing/presentation/pages/landing_page.dart';
import '../../features/marketing/presentation/pages/public_pages.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/referral_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/question_paper/presentation/pages/question_paper_pages.dart';
import '../../features/quiz/presentation/pages/quiz_pages.dart';
import '../../features/quiz/presentation/pages/quiz_teacher_pages.dart';
import '../../features/session/presentation/pages/study_page.dart';
import '../../features/teacher/presentation/pages/role_dashboard_pages.dart';
import '../presentation/shell/app_shell.dart';
import 'go_router_refresh_stream.dart';
import 'route_paths.dart';

/// Builds the app router. Guards run in [redirect]:
///  - unauthenticated users are sent to /login for protected routes,
///  - authenticated users on auth screens are sent to /dashboard,
///  - role-gated prefixes redirect disallowed roles to /dashboard.
class AppRouter {
  AppRouter({required this.authBloc, required this.profileCubit});

  final AuthBloc authBloc;
  final ProfileCubit profileCubit;

  /// path-prefix → roles permitted to enter.
  static const Map<String, Set<AccountType>> _roleGates = {
    RoutePaths.parent: {AccountType.parent, AccountType.superAdmin},
    RoutePaths.teacher: {
      AccountType.teacher,
      AccountType.parent,
      AccountType.superAdmin,
    },
    RoutePaths.admin: {AccountType.superAdmin},
    RoutePaths.questionPaper: {AccountType.teacher, AccountType.superAdmin},
  };

  late final GoRouter router = GoRouter(
    initialLocation: RoutePaths.landing,
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(authBloc.stream),
      GoRouterRefreshStream(profileCubit.stream),
    ]),
    redirect: _redirect,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: _routes,
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final status = authBloc.state.status;
    final location = state.uri.path;

    // Wait until the cold-start check resolves.
    if (status == AuthStatus.unknown) return null;

    final authed = status == AuthStatus.authenticated;
    final isPublic = RoutePaths.isPublic(location);
    final isAuthScreen =
        location == RoutePaths.login || location == RoutePaths.signup;

    // Block protected routes for signed-out users.
    if (!authed && !isPublic && !RoutePaths.isLanding(location)) {
      return RoutePaths.login;
    }

    // Keep signed-in users out of the login/signup screens; land them on the
    // study flow (mirrors the frontend's post-login redirect to /study).
    if (authed && isAuthScreen) return RoutePaths.study;

    // Role gating (only once the profile/role is known).
    if (authed) {
      final role = profileCubit.state.role;
      if (role != null) {
        for (final entry in _roleGates.entries) {
          if (location.startsWith(entry.key) &&
              !entry.value.contains(role)) {
            // Frontend sends disallowed roles to the landing page.
            return RoutePaths.landing;
          }
        }
      }
    }
    return null;
  }

  static List<RouteBase> get _routes => [
        // ---- PUBLIC ----
        GoRoute(
            path: RoutePaths.landing, builder: (_, __) => const LandingPage()),
        GoRoute(
            path: RoutePaths.login, builder: (_, __) => const LoginPage()),
        GoRoute(
            path: RoutePaths.signup, builder: (_, __) => const SignupPage()),
        GoRoute(
          path: RoutePaths.verifyEmail,
          builder: (_, state) =>
              VerifyEmailPage(signupData: state.extra as SignupData?),
        ),
        GoRoute(
            path: RoutePaths.forgotPassword,
            builder: (_, __) => const ForgotPasswordPage()),
        GoRoute(
          path: RoutePaths.updatePassword,
          builder: (_, state) =>
              UpdatePasswordPage(token: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(path: RoutePaths.tryNow, builder: (_, __) => const TryNowPage()),
        GoRoute(
            path: RoutePaths.freePaperGenerator,
            builder: (_, __) => const PublicPaperGeneratorPage()),
        GoRoute(path: RoutePaths.feedback, builder: (_, __) => const FeedbackPage()),
        GoRoute(path: RoutePaths.blog, builder: (_, __) => const BlogPage()),
        GoRoute(
          path: RoutePaths.blogPost,
          builder: (_, state) =>
              BlogPostPage(slug: state.pathParameters['slug'] ?? ''),
        ),
        GoRoute(
            path: RoutePaths.forSchools, builder: (_, __) => const ForSchoolsPage()),
        GoRoute(
            path: RoutePaths.privacyPolicy,
            builder: (_, __) =>
                const LegalPage(eyebrow: 'LEGAL', title: 'Privacy policy.')),
        GoRoute(
            path: RoutePaths.termsOfService,
            builder: (_, __) =>
                const LegalPage(eyebrow: 'LEGAL', title: 'Terms of service.')),
        GoRoute(
          path: RoutePaths.studentPublic,
          builder: (_, state) =>
              StudentPublicProfilePage(userId: state.pathParameters['userId'] ?? ''),
        ),
        GoRoute(
          path: RoutePaths.classSubject,
          builder: (_, state) => SeoCataloguePage(
              title: 'Class ${state.pathParameters['classId']} · ${state.pathParameters['subjectId']}'),
        ),
        GoRoute(
          path: RoutePaths.classSubjectChapter,
          builder: (_, state) => SeoCataloguePage(
              isChapter: true,
              title: 'Chapter ${state.pathParameters['chapterId']}'),
        ),

        // ---- PROTECTED ----
        GoRoute(
            path: RoutePaths.study, builder: (_, __) => const StudyPage()),
        GoRoute(
            path: RoutePaths.dashboard, builder: (_, __) => const DashboardPage()),
        GoRoute(
            path: RoutePaths.profile, builder: (_, __) => const ProfilePage()),
        GoRoute(
            path: RoutePaths.settings, builder: (_, __) => const SettingsPage()),
        GoRoute(
            path: RoutePaths.progress, builder: (_, __) => const ProgressPage()),
        GoRoute(
            path: RoutePaths.referral, builder: (_, __) => const ReferralPage()),
        GoRoute(
            path: RoutePaths.quizzes, builder: (_, __) => const StudentQuizListPage()),
        GoRoute(
          path: RoutePaths.quizAttempt,
          builder: (_, state) => QuizAttemptPage(
            quizId: state.pathParameters['quizId'] ?? '',
            attemptId: state.pathParameters['attemptId'] ?? '',
          ),
        ),
        GoRoute(
          path: RoutePaths.quizResult,
          builder: (_, state) =>
              QuizResultPage(attemptId: state.pathParameters['attemptId'] ?? ''),
        ),
        GoRoute(
            path: RoutePaths.quizHistory, builder: (_, __) => const QuizHistoryPage()),

        // ---- ROLE-GATED ----
        GoRoute(
            path: RoutePaths.parent, builder: (_, __) => const ParentDashboardPage()),
        GoRoute(
            path: RoutePaths.teacher, builder: (_, __) => const TeacherDashboardPage()),
        GoRoute(
          path: '/teacher/subject/:subjectId',
          builder: (_, state) =>
              TeacherSubjectPage(subjectId: state.pathParameters['subjectId'] ?? ''),
        ),
        GoRoute(
            path: '/teacher/quizzes', builder: (_, __) => const TeacherQuizListPage()),
        GoRoute(path: '/teacher/quiz/new', builder: (_, __) => const QuizFormPage()),
        GoRoute(
          path: '/teacher/quiz/:quizId/questions',
          builder: (_, state) =>
              QuizQuestionManagerPage(quizId: state.pathParameters['quizId'] ?? ''),
        ),
        GoRoute(
          path: '/teacher/quiz/:quizId/analytics',
          builder: (_, state) =>
              QuizAnalyticsPage(quizId: state.pathParameters['quizId'] ?? ''),
        ),
        GoRoute(
          path: '/teacher/subject/:subjectId/student/:studentId',
          builder: (_, state) => TeacherStudentPage(
            subjectId: state.pathParameters['subjectId'] ?? '',
            studentId: state.pathParameters['studentId'] ?? '',
          ),
        ),
        GoRoute(
            path: '/teacher/ai-generator',
            builder: (_, __) => const TeacherAiGeneratorPage()),
        GoRoute(
            path: RoutePaths.admin, builder: (_, __) => const AdminDashboardPage()),
        GoRoute(
            path: RoutePaths.questionPaper,
            builder: (_, __) => const QuestionPaperGeneratorPage()),
        GoRoute(
          path: RoutePaths.questionPaperPreview,
          builder: (_, state) =>
              QuestionPaperPreviewPage(paperId: state.pathParameters['paperId'] ?? ''),
        ),
        GoRoute(
            path: RoutePaths.questionPaperHistory,
            builder: (_, __) => const QuestionPaperHistoryPage()),
      ];
}
