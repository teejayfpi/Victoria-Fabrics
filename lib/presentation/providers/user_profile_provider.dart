import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../domain/entities/saved_address.dart';
import '../../domain/entities/user_profile.dart';

/// Ensures a saved-address list has exactly one default.
///
/// When [defaultId] is given that address wins; otherwise the first flagged
/// default is kept and, if none is flagged, the first address is promoted. This
/// keeps checkout's pre-fill (which reads the default) from ever coming up empty.
List<SavedAddress> normaliseAddressDefaults(
  List<SavedAddress> addresses, {
  String? defaultId,
}) {
  if (addresses.isEmpty) return addresses;

  if (defaultId != null) {
    return [
      for (final a in addresses) a.copyWith(isDefault: a.id == defaultId),
    ];
  }

  final defaultIndex = addresses.indexWhere((a) => a.isDefault);
  final keep = defaultIndex >= 0 ? defaultIndex : 0;
  return [
    for (var i = 0; i < addresses.length; i++)
      addresses[i].copyWith(isDefault: i == keep),
  ];
}

/// Live profile (wishlist, addresses, notification preferences) for the
/// signed-in customer. Emits an empty profile while signed out or before the
/// document exists, so callers never have to null-check the container.
final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const UserProfile());
  return ref.watch(userRepositoryProvider).watch(user.uid);
});

/// The current profile without the async wrapper.
final userProfileValueProvider = Provider<UserProfile>((ref) {
  return ref.watch(userProfileProvider).valueOrNull ?? const UserProfile();
});

final wishlistIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(userProfileValueProvider).wishlistIds;
});

final isWishlistedProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(wishlistIdsProvider).contains(productId);
});

/// Mutations for the signed-in customer's profile data.
///
/// Each method reads the current value, computes the next value and persists
/// the whole field, so the UI layer stays free of Firestore details. Writes are
/// no-ops when no user is signed in.
class UserDataController {
  UserDataController(this._ref);

  final Ref _ref;

  String? get _uid => _ref.read(currentUserProvider)?.uid;

  UserProfile get _profile => _ref.read(userProfileValueProvider);

  // ─── Wishlist ─────────────────────────────────────────────────────

  /// Adds or removes [productId], returning true when it is now saved.
  Future<bool> toggleWishlist(String productId) async {
    final uid = _uid;
    final current = _profile.wishlistIds;
    final nowSaved = !current.contains(productId);
    final next = nowSaved
        ? [...current, productId]
        : current.where((id) => id != productId).toList();
    if (uid != null) {
      await _ref.read(userRepositoryProvider).setWishlist(uid, next);
    }
    return nowSaved;
  }

  Future<void> removeFromWishlist(String productId) async {
    final uid = _uid;
    if (uid == null) return;
    final next =
        _profile.wishlistIds.where((id) => id != productId).toList();
    await _ref.read(userRepositoryProvider).setWishlist(uid, next);
  }

  // ─── Addresses ────────────────────────────────────────────────────

  /// Inserts or replaces [address]. A newly added address becomes the default
  /// when it is the first one, or when it was explicitly flagged as default.
  Future<void> saveAddress(SavedAddress address) async {
    final uid = _uid;
    if (uid == null) return;

    final current = [..._profile.addresses];
    final index = current.indexWhere((a) => a.id == address.id);
    final shouldBeDefault = address.isDefault || current.isEmpty;

    if (index >= 0) {
      current[index] = address.copyWith(isDefault: shouldBeDefault);
    } else {
      current.add(address.copyWith(isDefault: shouldBeDefault));
    }

    await _persistAddresses(uid, current, defaultId: shouldBeDefault ? address.id : null);
  }

  Future<void> deleteAddress(String addressId) async {
    final uid = _uid;
    if (uid == null) return;

    final remaining =
        _profile.addresses.where((a) => a.id != addressId).toList();
    // normaliseAddressDefaults promotes another address when the default is the
    // one being removed.
    await _persistAddresses(uid, remaining);
  }

  Future<void> setDefaultAddress(String addressId) async {
    final uid = _uid;
    if (uid == null) return;
    await _persistAddresses(uid, _profile.addresses, defaultId: addressId);
  }

  /// The address used to pre-fill checkout: the default one, else the first.
  SavedAddress? defaultAddress() {
    final addresses = _profile.addresses;
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  Future<void> _persistAddresses(
    String uid,
    List<SavedAddress> addresses, {
    String? defaultId,
  }) async {
    final normalised = normaliseAddressDefaults(addresses, defaultId: defaultId);
    await _ref.read(userRepositoryProvider).setAddresses(uid, normalised);
  }

  // ─── Notification preferences ─────────────────────────────────────

  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    await _ref
        .read(userRepositoryProvider)
        .setNotificationPreferences(uid, preferences);
  }
}

final userDataControllerProvider = Provider<UserDataController>((ref) {
  return UserDataController(ref);
});
