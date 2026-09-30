import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/logging/app_logger.dart';
import 'core/providers/bootstrap_provider.dart';
import 'core/theme/app_theme.dart';
import 'admin/router/admin_router.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(
    () async {
      FlutterError.onError = (details) {
        AppLogger.error(
          'Flutter framework error',
          tag: 'admin_app',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      AppLogger.info(
        'Starting ${AppConstants.appName} Admin',
        tag: 'admin_app',
        context: {'env': AppConfig.environment.name},
      );

      try {
        await Firebase.initializeApp();
        await NotificationService.instance.init();
      } catch (error, stack) {
        AppLogger.error('Admin startup failed', tag: 'admin_app',
            error: error, stackTrace: stack);
        rethrow;
      }

      runApp(const ProviderScope(child: VictoriaFabricsAdminApp()));
    },
    (error, stack) {
      AppLogger.error('Uncaught zone error', tag: 'admin_app',
          error: error, stackTrace: stack);
    },
  );
}

class VictoriaFabricsAdminApp extends ConsumerWidget {
  const VictoriaFabricsAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(catalogueBootstrapProvider, (_, __) {});
    return MaterialApp.router(
      title: '${AppConstants.appName} Admin',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: adminRouter,
    );
  }
}
