import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  try {
    await Firebase.initializeApp();
    await NotificationService.instance.init();
    // Seed Firestore with default products if the store is brand new
    await FirestoreService.instance.seedProductsIfEmpty();
  } catch (error) {
    FlutterNativeSplash.remove();
    rethrow;
  }

  runApp(const ProviderScope(child: VictoriaFabricsApp()));
}

class VictoriaFabricsApp extends StatefulWidget {
  const VictoriaFabricsApp({super.key});

  @override
  State<VictoriaFabricsApp> createState() => _VictoriaFabricsAppState();
}

class _VictoriaFabricsAppState extends State<VictoriaFabricsApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

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
