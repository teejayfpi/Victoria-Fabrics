import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/domain/entities/saved_address.dart';
import 'package:fabric_haven/domain/entities/user_profile.dart';

const _address = SavedAddress(
  id: 'a1',
  label: 'Home',
  recipientName: 'Ada',
  phone: '08030000000',
  street: '15 Admiralty Way',
  city: 'Lekki',
  state: 'Lagos',
);

void main() {
  group('SavedAddress', () {
    test('formatted joins the parts that are present', () {
      expect(_address.formatted, '15 Admiralty Way, Lekki, Lagos');
    });

    test('formatted skips blank parts without leaving stray commas', () {
      final address = _address.copyWith(city: '');
      expect(address.formatted, '15 Admiralty Way, Lagos');
    });

    test('survives a toMap/fromMap round trip', () {
      final restored = SavedAddress.fromMap(_address.toMap());

      expect(restored.id, _address.id);
      expect(restored.label, _address.label);
      expect(restored.recipientName, _address.recipientName);
      expect(restored.phone, _address.phone);
      expect(restored.street, _address.street);
      expect(restored.city, _address.city);
      expect(restored.state, _address.state);
    });

    test('copyWith can flip the default flag without losing other fields', () {
      final address = _address.copyWith(isDefault: true);
      expect(address.isDefault, isTrue);
      expect(address.street, _address.street);
    });
  });

  group('NotificationPreferences', () {
    test('defaults to order and support alerts on, promotions off', () {
      const prefs = NotificationPreferences();
      expect(prefs.orderUpdates, isTrue);
      expect(prefs.supportReplies, isTrue);
      expect(prefs.promotions, isFalse);
    });

    test('an absent document falls back to the defaults', () {
      final prefs = NotificationPreferences.fromMap(null);
      expect(prefs.orderUpdates, isTrue);
      expect(prefs.promotions, isFalse);
    });

    test('reads stored values and round-trips through toMap', () {
      const prefs = NotificationPreferences(
        orderUpdates: false,
        promotions: true,
        supportReplies: false,
      );
      final restored = NotificationPreferences.fromMap(prefs.toMap());

      expect(restored.orderUpdates, isFalse);
      expect(restored.promotions, isTrue);
      expect(restored.supportReplies, isFalse);
    });
  });

  group('UserProfile.fromMap', () {
    test('an empty document yields empty collections and default prefs', () {
      final profile = UserProfile.fromMap(null);

      expect(profile.wishlistIds, isEmpty);
      expect(profile.addresses, isEmpty);
      expect(profile.notifications.orderUpdates, isTrue);
    });

    test('parses wishlist, addresses and preferences together', () {
      final profile = UserProfile.fromMap({
        'wishlist': ['p1', 'p2'],
        'addresses': [_address.toMap()],
        'notifications': {'promotions': true},
      });

      expect(profile.wishlistIds, ['p1', 'p2']);
      expect(profile.addresses.single.label, 'Home');
      expect(profile.notifications.promotions, isTrue);
      // Unspecified fields keep their defaults rather than becoming null.
      expect(profile.notifications.orderUpdates, isTrue);
    });

    test('ignores non-string wishlist entries instead of throwing', () {
      final profile = UserProfile.fromMap({
        'wishlist': ['p1', 42, null],
      });

      expect(profile.wishlistIds, ['p1']);
    });

    test('reads the editable contact details', () {
      final profile = UserProfile.fromMap({
        'displayName': 'Ada Obi',
        'phone': '08030000000',
      });

      expect(profile.displayName, 'Ada Obi');
      expect(profile.phone, '08030000000');
    });

    test('contact details default to empty when absent', () {
      final profile = UserProfile.fromMap({'wishlist': ['p1']});
      expect(profile.displayName, isEmpty);
      expect(profile.phone, isEmpty);
    });
  });
}
