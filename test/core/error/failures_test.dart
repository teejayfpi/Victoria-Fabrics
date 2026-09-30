import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/core/error/failures.dart';

void main() {
  group('Result', () {
    test('Success carries data and reports success', () {
      const result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.dataOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Error carries a failure and reports error', () {
      const result = Error<int>(NetworkFailure());

      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('fold dispatches to the matching branch', () {
      const success = Success<String>('ok');
      expect(
        success.fold(onSuccess: (d) => 'success:$d', onError: (f) => 'error'),
        'success:ok',
      );

      const failure = Error<String>(AuthFailure());
      expect(
        failure.fold(
            onSuccess: (d) => 'success', onError: (f) => 'error:${f.code}'),
        'error:AUTH_FAILURE',
      );
    });
  });

  group('ValidationFailure', () {
    test('exposes per-field errors', () {
      const failure = ValidationFailure(
        fieldErrors: {'email': 'Email is required'},
      );

      expect(failure.fieldErrors, containsPair('email', 'Email is required'));
      expect(failure.code, 'VALIDATION_FAILURE');
    });
  });
}
