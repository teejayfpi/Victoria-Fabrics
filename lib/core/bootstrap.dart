import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../services/notification_service.dart';

/// Result of initialising the app's backend dependencies.
class BootstrapResult {
  final Object? error;

  const BootstrapResult({this.error});

  bool get ok => error == null;
}

/// Initialises Firebase and notifications.
///
/// Never throws: a failure here must not prevent the UI from coming up, or the
/// user is left staring at the native splash with no way forward. The caller
/// renders [StartupErrorScreen] when [BootstrapResult.ok] is false.
///
/// Catalogue seeding is deliberately *not* part of startup: writing to
/// Firestore now requires an admin account (see firestore.rules), so it is
/// triggered from the admin Products screen instead.
Future<BootstrapResult> bootstrap() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    return BootstrapResult(error: error);
  }

  // Notifications are non-critical: local notification setup failing should
  // not stop the app from working.
  try {
    await NotificationService.instance.init();
  } catch (error) {
    debugPrint('[Victoria Fabrics] Notification setup failed: $error');
  }

  return const BootstrapResult();
}