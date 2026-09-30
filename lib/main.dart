import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/logging/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'services/notification_service.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Route every uncaught error through the logger / crash reporter instead of
  // letting it reach the default zone handler silently.
  runZonedGuarded(
    () async {
      FlutterError.onError = (details) {
        AppLogger.error(
          'Flutter framework error',
          tag: 'app',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      AppLogger.info(
        'Starting ${AppConstants.appName}',
        tag: 'app',
        context: {'env': AppConfig.environment.name},
      );

      try {
        await Firebase.initializeApp();
        await NotificationService.instance.init();
      } catch (error, stack) {
        AppLogger.error('Startup failed', tag: 'app',
            error: error, stackTrace: stack);
        FlutterNativeSplash.remove();
        rethrow;
      }

      FlutterNativeSplash.remove();
      runApp(const ProviderScope(child: VictoriaFabricsApp()));
    },
    (error, stack) {
      AppLogger.error('Uncaught zone error', tag: 'app',
          error: error, stackTrace: stack);
    },
  );
}

class VictoriaFabricsApp extends StatelessWidget {
  const VictoriaFabricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
