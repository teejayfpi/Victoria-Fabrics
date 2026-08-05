import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'admin/router/admin_router.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  await FirestoreService.instance.seedProductsIfEmpty();
  _startAdminListeners();
  runApp(const ProviderScope(child: VictoriaFabricsAdminApp()));
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
  });
}

class VictoriaFabricsAdminApp extends StatelessWidget {
  const VictoriaFabricsAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Victoria Fabrics Admin',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: adminRouter,
    );
  }
}
