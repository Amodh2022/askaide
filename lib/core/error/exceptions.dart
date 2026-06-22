/// Low-level exceptions thrown by data sources. They are caught in repository
/// implementations and mapped to [Failure]s — the presentation layer never
/// sees a raw exception.
class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection']);
  final String message;
}

class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Session expired']);
  final String message;
}

class CacheException implements Exception {
  CacheException([this.message = 'Cache error']);
  final String message;
}

class ValidationException implements Exception {
  ValidationException(this.message);
  final String message;
}
