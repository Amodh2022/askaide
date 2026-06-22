/// Centralised API path constants. Methods build paths that contain path
/// parameters; bare endpoints are `static const` strings. All paths are
/// relative to [AppConstants.apiBaseUrl].
class Endpoints {
  Endpoints._();

  // ---- AUTH --------------------------------------------------------------
  static const String sendOtp = '/authenticate/sendotp';
  static const String signup = '/authenticate/signup';
  static const String login = '/authenticate/login';
  static const String resetPasswordToken = '/authenticate/reset-password-token';
  static const String resetPassword = '/authenticate/reset-password';

  // ---- PROFILE -----------------------------------------------------------
  static const String getUserDetails = '/profile/getUserDetails';
  static const String updateDisplayPicture = '/profile/updateDisplayPicture';
  static const String updateProfile = '/profile/updateProfile';
  static const String deleteProfile = '/profile/deleteProfile';
  static const String deleteProfilePhoto = '/profile/deleteProfilePhoto';
  static const String changePassword = '/auth/changepassword';

  // ---- STUDY -------------------------------------------------------------
  static const String studyConfiguration = '/study/configuration';
  static const String sessions = '/sessions';
  static const String userAnswers = '/user-answers';

  /// Post-session Net Promoter Score survey (mirrors React `submitNps`).
  static const String sessionFeedbackNps = '/session-feedback/nps';

  static String topics(String classId, String subjectId) =>
      '/topics/class/$classId/subject/$subjectId';

  static String questionsBatch({
    required String chapterId,
    required String type,
    required String difficulty,
    required String sessionId,
  }) =>
      '/questions/batch/chapter/$chapterId/type/$type/difficulty/$difficulty/session/$sessionId';

  // ---- PROGRESS ----------------------------------------------------------
  static String progress(String userId) => '/progress/user/$userId';

  static String topicProgress(String userId, String subjectId) =>
      '/topic-progress/progress/$userId/subject/$subjectId';

  static String aiInsightsSubject(String userId, String subjectId) =>
      '/topic-progress/ai-insights/userid/$userId/subject/$subjectId';

  static String aiInsightsChapter(String userId, String chapterId) =>
      '/topic-progress/ai-insights/userid/$userId/chapter/$chapterId';

  // ---- CHAPTERS ----------------------------------------------------------
  static String chapters(String classId, String subjectId) =>
      '/chapters/class/$classId/subject/$subjectId';
  static const String chaptersCreateWithPdf = '/chapters/create-with-pdf';
  static const String chaptersRoot = '/chapters';

  // ---- ADMIN -------------------------------------------------------------
  static const String school = '/school';
  static const String teacher = '/teacher';
  static const String teacherGetAll = '/teacher/get-all';
  static const String teachersBulk = '/teachers/bulk';
  static const String student = '/student';
  static const String studentGetAll = '/student/get-all';
  static const String studentCreate = '/student/create';
  static const String teacherStudents = '/teacher-students';
  static const String classes = '/classes';
  static String subjectsByClass(String classId) => '/subjects/class/$classId';

  // ---- QUIZ --------------------------------------------------------------
  static const String quizzes = '/quizzes';
  static String quizAttempt(String quizId) => '/quizzes/$quizId/attempt';
  static String quizResult(String attemptId) => '/quizzes/result/$attemptId';
  static const String quizHistory = '/quizzes/history';

  // ---- QUESTION PAPER ----------------------------------------------------
  static const String questionPaper = '/question-paper';
  static const String questionPaperPdf = '/question-paper/pdf';

  // ---- DASHBOARDS / MISC -------------------------------------------------
  static const String teacherDashboard = '/teacher-dashboard';
  static const String parent = '/parent';
  static const String badges = '/badges';

  // ---- DASHBOARD / PROGRESS / RETENTION ---------------------------------
  static String userProgress(String userId) => '/progress/user/$userId';
  static String streak(String userId) => '/streaks/$userId';
  static String masterySummary(String userId) =>
      '/topic-progress/mastery-summary/$userId';
  static String sessionsByUser(String userId) => '/sessions/user/$userId';
  static String badgesFor(String userId) => '/badges/$userId';
  static const String leaderboard = '/leaderboard';
  static const String publicStats = '/stats/public';
  static const String feedback = '/feedback';
  static String dailyChallenge(String userId) => '/daily-challenge/$userId';
  static String lastIncompleteSession(String userId) =>
      '/sessions/last-incomplete/$userId';

  // ---- QUIZ (correct singular paths from the live API) -------------------
  static const String quizStudentAvailable = '/quiz/student/available';
  static const String quizStudentHistory = '/quiz/student/history';
  static String quizStart(String quizId) => '/quiz/$quizId/start';
  static String quizInProgress(String quizId) => '/quiz/$quizId/in-progress';
  static String quizAttemptAnswer(String attemptId) =>
      '/quiz/attempt/$attemptId/answer';
  static String quizAttemptSubmit(String attemptId) =>
      '/quiz/attempt/$attemptId/submit';
  static String quizAttemptGet(String attemptId) => '/quiz/attempt/$attemptId';
  static String quizAttemptResult(String attemptId) =>
      '/quiz/attempt/$attemptId/result';

  // ---- REFERRAL / GOALS --------------------------------------------------
  static const String referralMyCode = '/referral/my-code';
  static String referralRedeem(String code) => '/referral/redeem/$code';
  static const String goals = '/goals';

  // ---- QUESTION PAPER ----------------------------------------------------
  static const String questionPaperHistoryPath = '/question-paper/history';
  static const String questionPaperPublicGenerate = '/question-paper/public/generate';
  static String questionPaperPreview(String paperId) =>
      '/question-paper/$paperId/preview';
  static String questionPaperPdfUrl(String paperId) =>
      '/question-paper/$paperId/pdf';
  static String questionPaperDelete(String paperId) => '/question-paper/$paperId';

  // ---- TEACHER DASHBOARD -------------------------------------------------
  static String teacherAssignments(String teacherId) =>
      '/teacher-dashboard/$teacherId/my-assignments';
  static String teacherSubjectDashboard(String teacherId, String subjectId) =>
      '/teacher-dashboard/$teacherId/subject/$subjectId/dashboard';
  static String teacherStudentsList(String teacherId, String subjectId) =>
      '/teacher-dashboard/$teacherId/subject/$subjectId/students';
  static String teacherWeakTopics(String teacherId, String subjectId) =>
      '/teacher-dashboard/$teacherId/subject/$subjectId/weak-topics';
  static String teacherActivity(String teacherId, String subjectId) =>
      '/teacher-dashboard/$teacherId/subject/$subjectId/activity';
  static String teacherStudentProgress(
          String teacherId, String studentId, String subjectId) =>
      '/teacher-dashboard/$teacherId/student/$studentId/subject/$subjectId/progress';

  // ---- PARENT DASHBOARD --------------------------------------------------
  static const String parentChildren = '/parent-dashboard/children';
  static String parentChildOverview(String childId) =>
      '/parent-dashboard/child/$childId/overview';

  // ---- AI ASSISTANT ------------------------------------------------------
  static const String aiProcess = '/ai-assistant';
  static const String aiConversations = '/ai-assistant/conversations';
  static String aiConversationMessages(String id) =>
      '/ai-assistant/conversations/$id/messages';
  static String aiConversation(String id) => '/ai-assistant/conversations/$id';
}
