import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/logging/app_logger.dart';

/// Local notification channel and delivery, shared by both apps.
///
/// Each app is a separate install (distinct applicationId) so it owns its own
/// permission grant and channel. The customer app uses the default channel;
/// the admin app uses a separate channel so staff can mute customer promos
/// without losing order alerts.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String customerChannelId = 'victoria_fabrics_channel';
  static const String adminChannelId = 'victoria_fabrics_admin_channel';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextId = 0;

  bool get isInitialized => _initialized;

  Future<void> init({bool admin = false}) async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    final channel = AndroidNotificationChannel(
      admin ? adminChannelId : customerChannelId,
      admin ? 'Victoria Fabrics Admin' : 'Victoria Fabrics',
      description: admin
          ? 'New orders and support tickets'
          : 'Order and support updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);

    // Android 13+ requires the runtime POST_NOTIFICATIONS grant. Request it
    // once on startup; a denial is not fatal, alerts simply stay silent.
    try {
      await android?.requestNotificationsPermission();
    } catch (error, stack) {
      AppLogger.warning(
        'Notification permission request failed',
        tag: 'notifications',
        error: error,
        stackTrace: stack,
      );
    }

    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    bool admin = false,
  }) async {
    if (!_initialized) await init(admin: admin);

    final channelId = admin ? adminChannelId : customerChannelId;
    final androidDetails = AndroidNotificationDetails(
      channelId,
      admin ? 'Victoria Fabrics Admin' : 'Victoria Fabrics',
      channelDescription: admin
          ? 'New orders and support tickets'
          : 'Order and support updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      _nextId++,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}
