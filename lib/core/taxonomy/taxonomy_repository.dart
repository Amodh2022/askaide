import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';
import '../network/api_helpers.dart';
import '../network/endpoints.dart';

/// A selectable class / subject / chapter item.
class TaxItem extends Equatable {
  const TaxItem({required this.id, required this.name});
  final String id;
  final String name;

  factory TaxItem.fromJson(Map<dynamic, dynamic> j) => TaxItem(
        id: j.str(['_id', 'id']),
        name: j.str(['name', 'subjectName', 'chapterName', 'className'], 'Item'),
      );

  @override
  List<Object?> get props => [id, name];
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
