import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/startup_error_screen.dart';
import 'presentation/router/app_router.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  final result = await bootstrap();

  runApp(
    ProviderScope(
      child: VictoriaFabricsApp(startupError: result.error),
    ),
  );
}

class VictoriaFabricsApp extends StatefulWidget {
  /// Non-null when backend initialisation failed.
  final Object? startupError;

  const VictoriaFabricsApp({super.key, this.startupError});

  @override
  State<VictoriaFabricsApp> createState() => _VictoriaFabricsAppState();
}

class _VictoriaFabricsAppState extends State<VictoriaFabricsApp> {
  @override
  void initState() {
    super.initState();
    // Hand the native splash over to the Flutter splash as soon as the first
    // frame is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startupError != null) {
      return MaterialApp(
        title: 'Victoria Fabrics',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: StartupErrorScreen(error: widget.startupError),
      );
    }

    return MaterialApp.router(
      title: 'Victoria Fabrics',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
