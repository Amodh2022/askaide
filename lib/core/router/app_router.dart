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

    // Keep signed-in users out of the login/signup screens AND off the public
    // landing page (the cold-start initialLocation), landing them straight on
    // the study flow (mirrors the frontend's post-login redirect to /study).
    if (authed && (isAuthScreen || RoutePaths.isLanding(location))) {
      return RoutePaths.study;
    }

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
        _route(RoutePaths.landing, (_, __) => const LandingPage()),
        _route(RoutePaths.login, (_, __) => const LoginPage()),
        _route(RoutePaths.signup, (_, __) => const SignupPage()),
        _route(
          RoutePaths.verifyEmail,
          (_, state) => VerifyEmailPage(signupData: state.extra as SignupData?),
        ),
        _route(RoutePaths.forgotPassword, (_, __) => const ForgotPasswordPage()),
        _route(
          RoutePaths.updatePassword,
          (_, state) =>
              UpdatePasswordPage(token: state.pathParameters['id'] ?? ''),
        ),
        _route(RoutePaths.tryNow, (_, __) => const TryNowPage()),
        _route(RoutePaths.freePaperGenerator,
            (_, __) => const PublicPaperGeneratorPage()),
        _route(RoutePaths.feedback, (_, __) => const FeedbackPage()),
        _route(RoutePaths.blog, (_, __) => const BlogPage()),
        _route(
          RoutePaths.blogPost,
          (_, state) => BlogPostPage(slug: state.pathParameters['slug'] ?? ''),
        ),
        _route(RoutePaths.forSchools, (_, __) => const ForSchoolsPage()),
        _route(
            RoutePaths.privacyPolicy,
            (_, __) =>
                const LegalPage(eyebrow: 'LEGAL', title: 'Privacy policy.')),
        _route(
            RoutePaths.termsOfService,
            (_, __) =>
                const LegalPage(eyebrow: 'LEGAL', title: 'Terms of service.')),
        _route(
          RoutePaths.studentPublic,
          (_, state) => StudentPublicProfilePage(
              userId: state.pathParameters['userId'] ?? ''),
        ),
        _route(
          RoutePaths.classSubject,
          (_, state) => SeoCataloguePage(
              title:
                  'Class ${state.pathParameters['classId']} · ${state.pathParameters['subjectId']}'),
        ),
        _route(
          RoutePaths.classSubjectChapter,
          (_, state) => SeoCataloguePage(
              isChapter: true,
              title: 'Chapter ${state.pathParameters['chapterId']}'),
        ),

        // ---- PROTECTED ----
        _route(RoutePaths.study, (_, __) => const StudyPage()),
        _route(RoutePaths.dashboard, (_, __) => const DashboardPage()),
        _route(RoutePaths.profile, (_, __) => const ProfilePage()),
        _route(RoutePaths.settings, (_, __) => const SettingsPage()),
        _route(RoutePaths.progress, (_, __) => const ProgressPage()),
        _route(RoutePaths.referral, (_, __) => const ReferralPage()),
        _route(RoutePaths.quizzes, (_, __) => const StudentQuizListPage()),
        _route(
          RoutePaths.quizAttempt,
          (_, state) => QuizAttemptPage(
            quizId: state.pathParameters['quizId'] ?? '',
            attemptId: state.pathParameters['attemptId'] ?? '',
          ),
        ),
        _route(
          RoutePaths.quizResult,
          (_, state) =>
              QuizResultPage(attemptId: state.pathParameters['attemptId'] ?? ''),
        ),
        _route(RoutePaths.quizHistory, (_, __) => const QuizHistoryPage()),

        // ---- ROLE-GATED ----
        _route(RoutePaths.parent, (_, __) => const ParentDashboardPage()),
        _route(RoutePaths.teacher, (_, __) => const TeacherDashboardPage()),
        _route(
          '/teacher/subject/:subjectId',
          (_, state) => TeacherSubjectPage(
              subjectId: state.pathParameters['subjectId'] ?? ''),
        ),
        _route('/teacher/quizzes', (_, __) => const TeacherQuizListPage()),
        _route('/teacher/quiz/new', (_, __) => const QuizFormPage()),
        _route(
          '/teacher/quiz/:quizId/questions',
          (_, state) => QuizQuestionManagerPage(
              quizId: state.pathParameters['quizId'] ?? ''),
        ),
        _route(
          '/teacher/quiz/:quizId/analytics',
          (_, state) =>
              QuizAnalyticsPage(quizId: state.pathParameters['quizId'] ?? ''),
        ),
        _route(
          '/teacher/subject/:subjectId/students',
          (_, state) => TeacherStudentsPage(subjectId: state.pathParameters['subjectId'] ?? ''),
        ),
        _route(
          '/teacher/subject/:subjectId/chapter/:chapterId',
          (_, state) => TeacherChapterPage(
            subjectId: state.pathParameters['subjectId'] ?? '',
            chapterId: state.pathParameters['chapterId'] ?? '',
          ),
        ),
        _route(
          '/teacher/subject/:subjectId/weak-topics',
          (_, state) => TeacherWeakTopicsPage(subjectId: state.pathParameters['subjectId'] ?? ''),
        ),
        _route(
          '/teacher/subject/:subjectId/activity',
          (_, state) => TeacherActivityPage(subjectId: state.pathParameters['subjectId'] ?? ''),
        ),
        _route(
          '/teacher/subject/:subjectId/student/:studentId',
          (_, state) => TeacherStudentPage(
            subjectId: state.pathParameters['subjectId'] ?? '',
            studentId: state.pathParameters['studentId'] ?? '',
          ),
        ),
        _route(
            '/teacher/ai-generator', (_, __) => const TeacherAiGeneratorPage()),
        _route(RoutePaths.admin, (_, __) => const AdminDashboardPage()),
        _route(RoutePaths.questionPaper,
            (_, __) => const QuestionPaperGeneratorPage()),
        _route(
          RoutePaths.questionPaperPreview,
          (_, state) => QuestionPaperPreviewPage(
              paperId: state.pathParameters['paperId'] ?? ''),
        ),
        _route(RoutePaths.questionPaperHistory,
            (_, __) => const QuestionPaperHistoryPage()),
      ];

  static GoRoute _route(
    String path,
    Widget Function(BuildContext, GoRouterState) builder,
  ) =>
      GoRoute(
        path: path,
        pageBuilder: (context, state) => NoTransitionPage(
          child: builder(context, state),
        ),
      );
}
