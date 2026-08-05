import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  // Seed Firestore with default products if the store is brand new
  await FirestoreService.instance.seedProductsIfEmpty();
  runApp(const ProviderScope(child: VictoriaFabricsApp()));
}

class VictoriaFabricsApp extends StatelessWidget {
  const VictoriaFabricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Victoria Fabrics',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
