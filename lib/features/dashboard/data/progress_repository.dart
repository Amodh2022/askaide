import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/api_helpers.dart';
import '../../../core/network/endpoints.dart';
import 'progress_models.dart';

/// Backs the `/progress` screen: class/subject configuration, per-subject topic
/// progress, and best-effort AI insights. Mirrors the frontend `studyApi`.
class ProgressRepository {
  ProgressRepository(this._dio);
  final Dio _dio;

  Future<Either<Failure, List<ClassConfig>>> configuration() => guardEither(() async {
        final res = await _dio.get(Endpoints.studyConfiguration);
        return res.dataList().whereType<Map>().map(ClassConfig.fromJson).toList();
      });

  Future<Either<Failure, SubjectProgressData>> topicProgress(
          String userId, String subjectId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.topicProgress(userId, subjectId));
        return SubjectProgressData.fromJson(res.dataMap());
      });

  /// AI learning-coach insight for a subject; null on any failure.
  Future<String?> subjectInsight(String userId, String subjectId) async {
    try {
      final res = await _dio.get(Endpoints.aiInsightsSubject(userId, subjectId));
      return res.dataMap().str(['insight']);
    } catch (_) {
      return null;
    }
  }

  /// AI learning-coach insight for a chapter; null on any failure.
  Future<String?> chapterInsight(String userId, String chapterId) async {
    try {
      final res = await _dio.get(Endpoints.aiInsightsChapter(userId, chapterId));
      return res.dataMap().str(['insight']);
    } catch (_) {
      return null;
    }
  }
}
