import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/core/validation/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null, empty and whitespace', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('accepts a non-empty value', () {
      expect(Validators.required('Lagos'), isNull);
    });
  });

  group('Validators.email', () {
    test('accepts valid addresses', () {
      expect(Validators.email('ada@victoriafabrics.ng'), isNull);
      expect(Validators.email('ada+orders@example.co.uk'), isNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
    });
  });

  group('Validators.phone', () {
    test('accepts Nigerian formats', () {
      expect(Validators.phone('08012345678'), isNull);
      expect(Validators.phone('+2348012345678'), isNull);
      expect(Validators.phone('0703 123 4567'), isNull);
    });

    test('rejects too-short or invalid prefixes', () {
      expect(Validators.phone('08012345'), isNotNull);
      expect(Validators.phone('02012345678'), isNotNull);
    });
  });

  group('Validators.normalisePhone', () {
    test('normalises local numbers to +234', () {
      expect(Validators.normalisePhone('08012345678'), '+2348012345678');
      expect(Validators.normalisePhone('+2348012345678'), '+2348012345678');
      expect(Validators.normalisePhone('0703 123 4567'), '+2347031234567');
    });
  });

  group('Validators.password', () {
    test('enforces a minimum length', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough1'), isNull);
    });
  });

  group('Validators.message', () {
    test('enforces minimum and maximum length', () {
      expect(Validators.message('too short'), isNotNull);
      expect(Validators.message('This is a valid message.'), isNull);
      expect(Validators.message('x' * 1001), isNotNull);
    });
  });
}
