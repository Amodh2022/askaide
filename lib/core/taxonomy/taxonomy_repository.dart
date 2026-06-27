import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';
import '../network/api_helpers.dart';
import '../network/endpoints.dart';

/// A selectable class / subject / chapter item. The chapter-specific fields
/// ([number], [comingSoon], [isStartable]) are absent (default) for class and
/// subject items; they let this serve as the single taxonomy source of truth
/// for both the generic pickers and the study config funnel.
class TaxItem extends Equatable {
  const TaxItem({
    required this.id,
    required this.name,
    this.number,
    this.comingSoon = false,
    this.isStartable = true,
  });
  final String id;
  final String name;

  /// Chapter ordering number, when the payload carries one.
  final int? number;

  /// Chapter is announced but not yet available for practice.
  final bool comingSoon;

  /// False when the backend marks a chapter as not yet startable (e.g. no
  /// questions generated) — shown in the list but not selectable.
  final bool isStartable;

  factory TaxItem.fromJson(Map<dynamic, dynamic> j) => TaxItem(
        id: j.str(['_id', 'id']),
        name: j.str(['name', 'subjectName', 'chapterName', 'className'], 'Item'),
        number: (j['number'] ?? j['chapterNumber']) is num
            ? (j['number'] ?? j['chapterNumber']).toInt()
            : null,
        comingSoon: j['comingSoon'] == true ||
            j['coming_soon'] == true ||
            j['isAvailable'] == false,
        isStartable: j['isStartable'] != false,
      );

  @override
  List<Object?> get props => [id, name, number, comingSoon, isStartable];
}

/// Shared class → subject → chapter lookup, used by the question-paper generator
/// and teacher quiz builder. Backed by the same study/admin taxonomy endpoints.
class TaxonomyRepository {
  TaxonomyRepository(this._dio);
  final Dio _dio;

  Future<Either<Failure, List<TaxItem>>> classes() => guardEither(() async {
        final res = await _dio.get(Endpoints.classes);
        return res.dataList().whereType<Map>().map(TaxItem.fromJson).toList();
      });

  Future<Either<Failure, List<TaxItem>>> subjects(String classId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.subjectsByClass(classId));
        return res.dataList().whereType<Map>().map(TaxItem.fromJson).toList();
      });

  Future<Either<Failure, List<TaxItem>>> chapters(String classId, String subjectId) =>
      guardEither(() async {
        final res = await _dio.get(Endpoints.chapters(classId, subjectId));
        return res.dataList().whereType<Map>().map(TaxItem.fromJson).toList();
      });
}
