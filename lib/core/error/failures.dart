sealed class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_FAILURE',
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error. Please try again later.',
    super.code = 'SERVER_FAILURE',
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to load cached data.',
    super.code = 'CACHE_FAILURE',
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed. Please login again.',
    super.code = 'AUTH_FAILURE',
  });
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    super.message = 'Please check your input.',
    super.code = 'VALIDATION_FAILURE',
    this.fieldErrors,
  });
}

// Result type for functional error handling
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(data: final d) => d,
    Error<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Error<T>(failure: final f) => f,
  };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onError,
  }) {
    return switch (this) {
      Success<T>(data: final d) => onSuccess(d),
      Error<T>(failure: final f) => onError(f),
    };
  }
}