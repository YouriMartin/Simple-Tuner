/// Base exception class
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

/// Audio-related exceptions
class AudioException extends AppException {
  const AudioException(super.message);

  @override
  String toString() => 'AudioException: $message';
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException(super.message);

  @override
  String toString() => 'PermissionException: $message';
}

/// Cache/Storage-related exceptions
class CacheException extends AppException {
  const CacheException(super.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Network-related exceptions
class ServerException extends AppException {
  const ServerException(super.message);

  @override
  String toString() => 'ServerException: $message';
}
