import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';

/// Shared plumbing for the feature repositories built on top of Dio. Keeps each
/// repository compact: wrap a remote call in [guardEither] to get a
/// `Either<Failure, T>`, and use the response helpers to dig values out of the
/// backend's `{ success, data }` envelopes defensively.

/// Runs [body], mapping any low-level exception to a [Failure].
Future<Either<Failure, T>> guardEither<T>(Future<T> Function() body) async {
  try {
    return Right(await body());
  } on UnauthorizedException catch (e) {
    return Left(UnauthorizedFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on DioException catch (e) {
    final inner = e.error;
    if (inner is ServerException) {
      return Left(ServerFailure(inner.message, statusCode: inner.statusCode));
    }
    if (inner is NetworkException) return Left(NetworkFailure(inner.message));
    if (inner is UnauthorizedException) {
      return Left(UnauthorizedFailure(inner.message));
    }
    return Left(ServerFailure(e.message ?? 'Network error'));
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}

/// Response/JSON helpers. The backend usually wraps payloads in
/// `{ success, data }`, but some endpoints return the object/list directly —
/// these helpers tolerate both, and several common key aliases.
extension ResponseX on Response<dynamic> {
  /// Unwraps the most likely "data" object from a response.
  Map<String, dynamic> dataMap([List<String> keys = const ['data']]) {
    final d = data;
    if (d is Map) {
      for (final k in keys) {
        if (d[k] is Map) return Map<String, dynamic>.from(d[k] as Map);
      }
      return Map<String, dynamic>.from(d);
    }
    return const {};
  }

  /// Unwraps the most likely list from a response (handles many key aliases).
  List<dynamic> dataList([List<String> keys = const ['data']]) {
    final d = data;
    if (d is List) return d;
    if (d is Map) {
      for (final k in [
        ...keys,
        'data',
        'items',
        'results',
        'questions',
        'quizzes',
        'attempts',
        'conversations',
        'messages',
        'students',
        'activities',
        'papers',
        'children',
        'links',
        'weakTopics',
        'subjectsProgress',
        'topics',
        'assignments',
        'badges',
      ]) {
        final v = d[k];
        if (v is List) return v;
        // one level of nesting: { data: { quizzes: [...] } }
        if (v is Map) {
          for (final k2 in ['quizzes', 'attempts', 'papers', 'items', 'results', 'conversations', 'messages']) {
            if (v[k2] is List) return v[k2] as List;
          }
        }
      }
    }
    return const [];
  }
}

/// Map helpers tolerant of Mongo `_id`/`id` and string/num coercion.
extension JsonMapX on Map<dynamic, dynamic> {
  String str(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final v = this[k];
      if (v != null) return v.toString();
    }
    return fallback;
  }

  int intval(List<String> keys, [int fallback = 0]) {
    for (final k in keys) {
      final v = this[k];
      if (v is num) return v.toInt();
      if (v is String) {
        final n = num.tryParse(v);
        if (n != null) return n.toInt();
      }
    }
    return fallback;
  }

  double dbl(List<String> keys, [double fallback = 0]) {
    for (final k in keys) {
      final v = this[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final n = num.tryParse(v);
        if (n != null) return n.toDouble();
      }
    }
    return fallback;
  }

  bool boolean(List<String> keys, [bool fallback = false]) {
    for (final k in keys) {
      final v = this[k];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      if (v is num) return v != 0;
    }
    return fallback;
  }

  List<dynamic> listAt(List<String> keys) {
    for (final k in keys) {
      if (this[k] is List) return this[k] as List;
    }
    return const [];
  }
}
