import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../services/notification_service.dart';

/// Watches the store for new orders and support tickets and raises a local
/// notification so staff notice them promptly.
///
/// Only runs in the admin app. Subscriptions are held so they can be cancelled
/// on sign-out, preventing privileged realtime listeners from outliving the
/// admin session.
class AdminAlertService {
  AdminAlertService._();
  static final AdminAlertService instance = AdminAlertService._();

  final _db = FirebaseFirestore.instance;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _subscriptions = [];

  bool _running = false;

  /// Starts the listeners. Safe to call more than once.
  void start() {
    if (_running) return;
    _running = true;

    _subscriptions.add(_watch(
      collection: AppConfig.ordersCollection,
      title: '🛒 New Order Received!',
      bodyBuilder: (addedCount) =>
          '$addedCount new order(s) waiting for your attention.',
    ));

    _subscriptions.add(_watch(
      collection: AppConfig.ticketsCollection,
      title: '🎫 New Support Ticket!',
      bodyBuilder: (_) => 'A customer needs help. Tap to view.',
    ));
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _watch({
    required String collection,
    required String title,
    required String Function(int addedCount) bodyBuilder,
  }) {
    var isFirstSnapshot = true;
    return _db.collection(collection).snapshots().listen(
      (snapshot) {
        // The first snapshot replays existing documents; only react to genuine
        // additions after that.
        if (isFirstSnapshot) {
          isFirstSnapshot = false;
          return;
        }
        final added = snapshot.docChanges
            .where((c) => c.type == DocumentChangeType.added)
            .length;
        if (added == 0) return;

        NotificationService.instance.showNotification(
          title: title,
          body: bodyBuilder(added),
          admin: true,
        );
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.warning('Admin alert stream failed',
            tag: 'admin_alerts', error: error, stackTrace: stack);
      },
    );
  }

  /// Cancels all listeners. Call when an administrator signs out or the
  /// admin session is otherwise invalidated.
  Future<void> stop() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _running = false;
  }
}
