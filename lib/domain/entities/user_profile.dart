import 'saved_address.dart';

/// Customer-controlled notification preferences.
///
/// These are app-level settings, not OS permissions: `orderUpdates` gates the
/// in-app notifications the app raises for order milestones, `promotions` gates
/// marketing messages. OS-level delivery is still controlled by the Android 13+
/// runtime permission requested in `NotificationService`.
class NotificationPreferences {
  const NotificationPreferences({
    this.orderUpdates = true,
    this.promotions = false,
    this.supportReplies = true,
  });

  final bool orderUpdates;
  final bool promotions;
  final bool supportReplies;

  /// True when at least one category is enabled; used to decide whether the
  /// OS permission is worth requesting.
  bool get anyEnabled => orderUpdates || promotions || supportReplies;

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? supportReplies,
  }) =>
      NotificationPreferences(
        orderUpdates: orderUpdates ?? this.orderUpdates,
        promotions: promotions ?? this.promotions,
        supportReplies: supportReplies ?? this.supportReplies,
      );

  Map<String, dynamic> toMap() => {
        'orderUpdates': orderUpdates,
        'promotions': promotions,
        'supportReplies': supportReplies,
      };

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    return NotificationPreferences(
      orderUpdates: map['orderUpdates'] as bool? ?? true,
      promotions: map['promotions'] as bool? ?? false,
      supportReplies: map['supportReplies'] as bool? ?? true,
    );
  }
}

/// The signed-in customer's saved data, stored on `users/{uid}`.
///
/// A single document keeps wishlist, addresses and preferences together so
/// they load in one snapshot and stay within the owner-scoped security rule.
class UserProfile {
  const UserProfile({
    this.wishlistIds = const [],
    this.addresses = const [],
    this.notifications = const NotificationPreferences(),
  });

  final List<String> wishlistIds;
  final List<SavedAddress> addresses;
  final NotificationPreferences notifications;

  factory UserProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserProfile();
    return UserProfile(
      wishlistIds: (map['wishlist'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      addresses: (map['addresses'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SavedAddress.fromMap)
          .toList(),
      notifications: NotificationPreferences.fromMap(
          map['notifications'] as Map<String, dynamic>?),
    );
  }
}
