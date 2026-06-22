import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question.dart';
import '../entities/study_config.dart';
import '../entities/study_session.dart';
import '../entities/study_taxonomy.dart';
import '../entities/user_answer.dart';
import '../repositories/session_repository.dart';

class GetClasses implements UseCase<List<ClassOption>, NoParams> {
  GetClasses(this._repo);
  final SessionRepository _repo;
  @override
  Future<Either<Failure, List<ClassOption>>> call(NoParams params) =>
      _repo.getClasses();
}

class GetSubjects implements UseCase<List<SubjectOption>, String> {
  GetSubjects(this._repo);
  final SessionRepository _repo;
  @override
  Future<Either<Failure, List<SubjectOption>>> call(String classId) =>
      _repo.getSubjects(classId);
}

class GetChaptersParams extends Equatable {
  const GetChaptersParams({required this.classId, required this.subjectId});
  final String classId;
  final String subjectId;
  @override
  List<Object?> get props => [classId, subjectId];
}

class GetChapters implements UseCase<List<ChapterOption>, GetChaptersParams> {
  GetChapters(this._repo);
  final SessionRepository _repo;
  @override
  Future<Either<Failure, List<ChapterOption>>> call(GetChaptersParams p) =>
      _repo.getChapters(p.classId, p.subjectId);
}

class FetchBatchParams extends Equatable {
  const FetchBatchParams({required this.config, required this.sessionId});
  final StudyConfig config;
  final String sessionId;
  @override
  List<Object?> get props => [config, sessionId];
}

class FetchQuestionBatch implements UseCase<List<Question>, FetchBatchParams> {
  FetchQuestionBatch(this._repo);
  final SessionRepository _repo;
  @override
  Future<Either<Failure, List<Question>>> call(FetchBatchParams p) =>
      _repo.fetchQuestionBatch(config: p.config, sessionId: p.sessionId);
}

class SubmitAnswers implements UseCase<Unit, List<UserAnswer>> {
  SubmitAnswers(this._repo);
  final SessionRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(List<UserAnswer> answers) =>
      _repo.submitAnswers(answers);
}

class SyncQueuedAnswers implements UseCase<int, NoParams> {
  SyncQueuedAnswers(this._repo);
  final SessionRepository _repo;
  @override
  Future<Either<Failure, int>> call(NoParams params) =>
      _repo.syncQueuedAnswers();
}

class SaveSession implements UseCase<Unit, StudySession> {
  SaveSession(this._repo);
  final SessionRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(StudySession session) =>
      _repo.saveSession(session);
}
