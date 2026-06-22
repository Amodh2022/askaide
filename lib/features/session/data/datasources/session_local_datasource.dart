import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/user_answer.dart';

/// Local persistence for session history and the offline answer queue, backed
/// by Hive boxes opened in [LocalStorageService].
abstract class SessionLocalDataSource {
  List<StudySession> readHistory();
  Future<void> upsertSession(StudySession session);
  Future<void> deleteSession(String id);

  void enqueueAnswers(List<UserAnswer> answers);
  List<UserAnswer> readQueuedAnswers();
  Future<void> clearQueuedAnswers(Iterable<String> keys);
  List<String> queuedKeys();
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  SessionLocalDataSourceImpl(this._storage);
  final LocalStorageService _storage;

  static String _answerKey(UserAnswer a) =>
      '${a.sessionId}_${a.questionId}_${a.answeredAtMillis}';

  @override
  List<StudySession> readHistory() {
    return _storage
        .readSessionHistory()
        .map(StudySession.fromJson)
        .toList()
      ..sort((a, b) => b.startedAtMillis.compareTo(a.startedAtMillis));
  }

  @override
  Future<void> upsertSession(StudySession session) =>
      _storage.upsertSession(session.id, session.toJson());

  @override
  Future<void> deleteSession(String id) => _storage.deleteSession(id);

  @override
  void enqueueAnswers(List<UserAnswer> answers) {
    for (final a in answers) {
      _storage.enqueueAnswer(_answerKey(a), a.copyWith(synced: false).toJson());
    }
  }

  @override
  List<UserAnswer> readQueuedAnswers() =>
      _storage.readAnswerQueue().map(UserAnswer.fromJson).toList();

  @override
  Future<void> clearQueuedAnswers(Iterable<String> keys) =>
      _storage.dequeueAnswers(keys);

  @override
  List<String> queuedKeys() => _storage.answerQueueKeys.toList();
}
