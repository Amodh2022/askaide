/// Canonical route paths + names. Grouped by access level to mirror the guard
/// logic in `app_router.dart`.
class RoutePaths {
  RoutePaths._();

  // ---- PUBLIC ------------------------------------------------------------
  /// Cold-start holding screen shown while the persisted token is checked, so
  /// the sign-in page never flashes for an already-authenticated user.
  static const String splash = '/splash';
  static const String landing = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String updatePassword = '/update-password/:id';
  static const String tryNow = '/try';
  static const String freePaperGenerator = '/free-paper-generator';
  static const String feedback = '/feedback';
  static const String blog = '/blog';
  static const String blogPost = '/blog/:slug';
  static const String forSchools = '/for-schools';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String studentPublic = '/student/:userId';
  static const String classSubject = '/class/:classId/subject/:subjectId';
  static const String classSubjectChapter =
      '/class/:classId/subject/:subjectId/chapter/:chapterId';

  // ---- PROTECTED ---------------------------------------------------------
  static const String study = '/study';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String progress = '/progress';
  static const String referral = '/referral';
  static const String quizzes = '/quizzes';
  static const String quizAttempt = '/quiz/:quizId/attempt/:attemptId';
  static const String quizResult = '/quiz/result/:attemptId';
  static const String quizHistory = '/quiz/history';

  // ---- ROLE-GATED --------------------------------------------------------
  static const String parent = '/parent';
  static const String teacher = '/teacher';
  static const String admin = '/admin';
  static const String questionPaper = '/question-paper';
  static const String questionPaperPreview = '/question-paper/preview/:paperId';
  static const String questionPaperHistory = '/question-paper/history';

  /// Public path prefixes (used by the guard to allow unauthenticated access).
  static const List<String> publicPrefixes = [
    '/login',
    '/signup',
    '/verify-email',
    '/forgot-password',
    '/update-password',
    '/try',
    '/free-paper-generator',
    '/feedback',
    '/blog',
    '/for-schools',
    '/privacy-policy',
    '/terms-of-service',
    '/student/',
    '/class/',
  ];

  /// Routes that hide ALL chrome (no navbar, sidebar, or bottom nav).
  /// Mirrors the frontend, which hides the navbar only on /login and /signup;
  /// forgot-password / update-password / verify-email keep the public navbar.
  static const List<String> bareRoutes = [splash, login, signup];

  static bool isLanding(String location) => location == landing;

  static bool isPublic(String location) {
    if (location == landing) return true;
    return publicPrefixes.any((p) => location.startsWith(p));
  }

  static bool isBare(String location) =>
      bareRoutes.any((r) => location == r);
}
