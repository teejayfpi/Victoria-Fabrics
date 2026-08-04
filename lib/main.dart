import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'admin/router/admin_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: FabricHavenApp()));
}

class FabricHavenApp extends StatelessWidget {
  const FabricHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Victoria Fabrics',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AppRouter(),
      routes: {
        '/admin': (context) => const AdminRouterWrapper(),
      },
    );
  }
}

// Wrapper for admin routes
class AdminRouterWrapper extends StatelessWidget {
  const AdminRouterWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Victoria Fabrics Admin',
      theme: AppTheme.lightTheme,
      routerConfig: adminRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Combined router for navigating between customer and admin
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Victoria Fabrics',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
