import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/startup_error_screen.dart';
import 'admin/router/admin_router.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  final result = await bootstrap();
  if (result.ok) _startAdminListeners();

  runApp(
    ProviderScope(
      child: VictoriaFabricsAdminApp(startupError: result.error),
    ),
  );
}

/// Firestore listeners that fire a sound notification whenever:
/// - A new customer order is placed
/// - A customer submits a support ticket
void _startAdminListeners() {
  bool ordersFirstSnapshot = true;
  bool ticketsFirstSnapshot = true;

  FirebaseFirestore.instance
      .collection('orders')
      .snapshots()
      .listen((snapshot) {
    if (ordersFirstSnapshot) {
      ordersFirstSnapshot = false;
      return;
    }
    final newOrders =
        snapshot.docChanges.where((c) => c.type == DocumentChangeType.added);
    if (newOrders.isNotEmpty) {
      NotificationService.instance.showNotification(
        title: '🛒 New Order Received!',
        body: '${newOrders.length} new order(s) waiting for your attention.',
      );
    }
  }, onError: (Object e) {
    debugPrint('[Victoria Fabrics] orders listener error: $e');
  });

  FirebaseFirestore.instance
      .collection('tickets')
      .snapshots()
      .listen((snapshot) {
    if (ticketsFirstSnapshot) {
      ticketsFirstSnapshot = false;
      return;
    }
    final newTickets =
        snapshot.docChanges.where((c) => c.type == DocumentChangeType.added);
    if (newTickets.isNotEmpty) {
      NotificationService.instance.showNotification(
        title: '🎫 New Support Ticket!',
        body: 'A customer needs help. Tap to view.',
      );
    }
  }, onError: (Object e) {
    debugPrint('[Victoria Fabrics] tickets listener error: $e');
  });
}

class VictoriaFabricsAdminApp extends StatelessWidget {
  /// Non-null when backend initialisation failed.
  final Object? startupError;

  const VictoriaFabricsAdminApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return MaterialApp(
        title: 'Victoria Fabrics Admin',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: StartupErrorScreen(error: startupError),
      );
    }

    return MaterialApp.router(
      title: 'Victoria Fabrics Admin',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: adminRouter,
    );
  }
}
