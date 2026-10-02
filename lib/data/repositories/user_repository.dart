import '../../core/error/failures.dart';
import '../../domain/entities/saved_address.dart';
import '../../domain/entities/user_profile.dart';
import '../../services/firestore_service.dart';
import 'guard.dart';

/// Per-customer profile data: wishlist, delivery addresses and notification
/// preferences, all held on the single `users/{uid}` document.
///
/// The security rule for `users/{uid}` already restricts reads and writes to
/// the owning account, so no rule change is required for these features.
class UserRepository {
  UserRepository(this._firestore);

  final FirestoreService _firestore;

  /// Live profile for [uid]. Emits an empty profile until the document exists.
  Stream<UserProfile> watch(String uid) => _firestore.userProfileStream(uid);

  Future<Result<void>> _merge(String uid, Map<String, dynamic> data) => guard(
        () => _firestore.mergeUserProfile(uid, data),
        tag: 'user_repo',
      );

  // ─── Wishlist ─────────────────────────────────────────────────────

  Future<Result<void>> setWishlist(String uid, List<String> productIds) =>
      _merge(uid, {'wishlist': productIds});

  // ─── Addresses ────────────────────────────────────────────────────

  /// Persists the full address list. Callers pass the list they want stored,
  /// which keeps default-flag handling (exactly one default) in one place.
  Future<Result<void>> setAddresses(
    String uid,
    List<SavedAddress> addresses,
  ) =>
      _merge(uid, {
        'addresses': addresses.map((a) => a.toMap()).toList(),
      });

  // ─── Notification preferences ─────────────────────────────────────

  Future<Result<void>> setNotificationPreferences(
    String uid,
    NotificationPreferences preferences,
  ) =>
      _merge(uid, {'notifications': preferences.toMap()});
}
