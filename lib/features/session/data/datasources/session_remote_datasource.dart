import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/endpoints.dart';
import '../../domain/entities/study_taxonomy.dart';
import '../models/question_model.dart';

abstract class SessionRemoteDataSource {
  Future<List<ClassOption>> getClasses();
  Future<List<SubjectOption>> getSubjects(String classId);
  Future<List<ChapterOption>> getChapters(String classId, String subjectId);
  Future<List<QuestionModel>> fetchQuestionBatch({
    required String chapterId,
    required String type,
    required String difficulty,
    required String sessionId,
  });
  Future<void> submitAnswers(List<Map<String, dynamic>> answers);
  Future<String> createSession(Map<String, dynamic> session);
  Future<void> submitNps(Map<String, dynamic> data);
}

class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  SessionRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  List<dynamic> _list(Response res, [List<String> keys = const ['data']]) {
    final data = res.data;
    if (data is List) return data;
    if (data is Map) {
      for (final k in [...keys, 'questions', 'results', 'items']) {
        if (data[k] is List) return data[k] as List;
      }
    }
    throw ServerException('Unexpected list response', statusCode: res.statusCode);
  }

  @override
  Future<List<ClassOption>> getClasses() async {
    final res = await _dio.get(Endpoints.classes);
    return _list(res)
        .map((e) => ClassOption(
              id: (e['_id'] ?? e['id']).toString(),
              name: (e['name'] ?? e['className'] ?? '').toString(),
            ))
        .toList();
  }

  @override
  Future<List<SubjectOption>> getSubjects(String classId) async {
    final res = await _dio.get(Endpoints.subjectsByClass(classId));
    return _list(res)
        .map((e) => SubjectOption(
              id: (e['_id'] ?? e['id']).toString(),
              name: (e['name'] ?? e['subjectName'] ?? '').toString(),
              classId: classId,
            ))
        .toList();
  }

  @override
  Future<List<ChapterOption>> getChapters(
    String classId,
    String subjectId,
  ) async {
    final res = await _dio.get(Endpoints.chapters(classId, subjectId));
    return _list(res)
        .map((e) => ChapterOption(
              id: (e['_id'] ?? e['id']).toString(),
              name: (e['name'] ?? e['chapterName'] ?? '').toString(),
              number: (e['number'] ?? e['chapterNumber']) is num
                  ? (e['number'] ?? e['chapterNumber']).toInt()
                  : null,
              subjectId: subjectId,
            ))
        .toList();
  }

  @override
  Future<List<QuestionModel>> fetchQuestionBatch({
    required String chapterId,
    required String type,
    required String difficulty,
    required String sessionId,
  }) async {
    final res = await _dio.get(
      Endpoints.questionsBatch(
        chapterId: chapterId,
        type: type,
        difficulty: difficulty,
        sessionId: sessionId,
      ),
    );
    return _list(res)
        .whereType<Map<String, dynamic>>()
        .map(QuestionModel.fromJson)
        .toList();
  }

  @override
  Future<void> submitAnswers(List<Map<String, dynamic>> answers) =>
      _dio.post(Endpoints.userAnswers, data: {'answers': answers});

  @override
  Future<void> submitNps(Map<String, dynamic> data) =>
      _dio.post(Endpoints.sessionFeedbackNps, data: data);

  @override
  Future<String> createSession(Map<String, dynamic> session) async {
    final res = await _dio.post(Endpoints.sessions, data: session);
    final data = res.data;
    if (data is Map) {
      return (data['_id'] ?? data['id'] ?? data['sessionId'] ?? '').toString();
    }
    return '';
  }
}
