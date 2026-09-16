import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';

class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
  });
}

/// Roles permitted to use the admin app.
const _adminRoles = ['admin', 'staff'];

/// Signals that a sign-in succeeded but the account is not an admin.
class NotAnAdminException implements Exception {
  final String email;

  const NotAnAdminException(this.email);

  @override
  String toString() =>
      'The account $email is not an administrator for this store.';
}

/// Admin authentication backed by Firebase Auth.
///
/// Authorisation is enforced in two places: this notifier refuses to expose an
/// [AdminUser] for a non-admin, and `firestore.rules` independently rejects
/// admin-only writes. The UI check alone is not a security boundary.
class AdminAuthNotifier extends StateNotifier<AdminUser?> {
  AdminAuthNotifier({FirebaseAuth? auth, FirestoreService? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirestoreService.instance,
        super(null);

  final FirebaseAuth _auth;
  final FirestoreService _firestore;

  /// Signs in with email/password. Throws [NotAnAdminException] when the
  /// credentials are valid but the account lacks an admin role, so the UI can
  /// distinguish "wrong password" from "not allowed".
  Future<AdminUser> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Sign-in succeeded but returned no user.');
    }

    final role = await _firestore.getUserRole(user.uid);
    if (role == null || !_adminRoles.contains(role)) {
      // Do not leave a non-admin session active.
      await _auth.signOut();
      throw NotAnAdminException(user.email ?? email);
    }

    final admin = AdminUser(
      id: user.uid,
      email: user.email ?? email,
      name: user.displayName ?? 'Store Admin',
      role: role,
      createdAt: user.metadata.creationTime,
    );
    state = admin;
    return admin;
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = null;
  }

  /// Re-establishes the session from a persisted Firebase Auth user.
  ///
  /// Called once per launch: Firebase keeps the credential across restarts, so
  /// the admin would otherwise be sent back to the login screen every time.
  /// Returns the restored admin, or null when there is no valid session.
  Future<AdminUser?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final role = await _firestore.getUserRole(user.uid);
    if (role == null || !_adminRoles.contains(role)) {
      // Role was revoked while the app was closed — drop the session.
      await _auth.signOut();
      return null;
    }

    final admin = AdminUser(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? 'Store Admin',
      role: role,
      createdAt: user.metadata.creationTime,
    );
    state = admin;
    return admin;
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminUser?>((ref) {
  return AdminAuthNotifier();
});

/// Resolves the persisted admin session once per app launch.
///
/// The router awaits this before deciding between the dashboard and the login
/// screen, so a signed-in admin never sees a login prompt flicker past.
final adminSessionRestoreProvider = FutureProvider<AdminUser?>((ref) {
  return ref.read(adminAuthProvider.notifier).restoreSession();
});

final isAdminLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthProvider) != null;
});