import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/domain/entities/saved_address.dart';
import 'package:fabric_haven/presentation/providers/user_profile_provider.dart';

SavedAddress _address(String id, {bool isDefault = false}) => SavedAddress(
      id: id,
      label: 'Address $id',
      recipientName: 'Ada',
      phone: '08030000000',
      street: '$id Test Street',
      city: 'Lekki',
      state: 'Lagos',
      isDefault: isDefault,
    );

void main() {
  group('normaliseAddressDefaults', () {
    test('an empty list stays empty', () {
      expect(normaliseAddressDefaults(const []), isEmpty);
    });

    test('promotes the first address when none is flagged', () {
      final result = normaliseAddressDefaults([
        _address('a'),
        _address('b'),
      ]);

      expect(result.where((a) => a.isDefault).length, 1);
      expect(result.first.isDefault, isTrue);
      expect(result.last.isDefault, isFalse);
    });

    test('keeps exactly one default when several are flagged', () {
      final result = normaliseAddressDefaults([
        _address('a'),
        _address('b', isDefault: true),
        _address('c', isDefault: true),
      ]);

      expect(result.where((a) => a.isDefault).length, 1);
      expect(result[1].isDefault, isTrue);
      expect(result[2].isDefault, isFalse);
    });

    test('defaultId overrides any existing flag', () {
      final result = normaliseAddressDefaults(
        [
          _address('a', isDefault: true),
          _address('b'),
        ],
        defaultId: 'b',
      );

      expect(result.firstWhere((a) => a.id == 'b').isDefault, isTrue);
      expect(result.firstWhere((a) => a.id == 'a').isDefault, isFalse);
    });

    test('removing the default leaves another address as default', () {
      // Mirrors deleteAddress: the list is filtered, then normalised.
      final remaining = [
        _address('a'),
        _address('b', isDefault: true),
      ].where((a) => a.id != 'b').toList();

      final result = normaliseAddressDefaults(remaining);
      expect(result.single.isDefault, isTrue);
    });
  });
}
