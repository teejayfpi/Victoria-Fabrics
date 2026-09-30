import '../../core/error/error_mapper.dart';
import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';

/// Executes an asynchronous operation and converts any thrown error into a
/// typed [Failure] via [ErrorMapper].
///
/// Repositories expose [Result]-returning methods so the UI layer can branch on
/// `Success`/`Error` without ever seeing a raw Firebase exception.
///
/// ```dart
/// final result = await guard(() => repo.loadProducts());
/// result.fold(
///   onSuccess: (products) => ...,
///   onError: (failure) => showError(failure.message),
/// );
/// ```
Future<Result<T>> guard<T>(
  Future<T> Function() operation, {
  String? tag,
}) async {
  try {
    return Success(await operation());
  } catch (error, stack) {
    AppLogger.error(
      'Operation failed',
      tag: tag ?? 'repository',
      error: error,
      stackTrace: stack,
    );
    return Error(ErrorMapper.toFailure(error, stack));
  }
}
