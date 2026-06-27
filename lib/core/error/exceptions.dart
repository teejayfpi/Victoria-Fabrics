class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error occurred',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Server error occurred',
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.originalError,
  });
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error occurred',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication error',
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    super.message = 'Validation error',
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalError,
  });
}