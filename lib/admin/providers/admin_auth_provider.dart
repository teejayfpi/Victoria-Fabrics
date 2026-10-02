import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/error_mapper.dart';
import '../../core/logging/app_logger.dart';
import '../../core/providers/auth_provider.dart';
import '../services/admin_alert_service.dart';

/// Administrative roles, ordered from least to most privileged.
enum AdminRole {
  viewer,
  staff,
  admin,
  superAdmin;

  static AdminRole? tryParse(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'viewer':
        return AdminRole.viewer;
      case 'staff':
        return AdminRole.staff;
      case 'admin':
        return AdminRole.admin;
      case 'super_admin':
      case 'superAdmin':
        return AdminRole.superAdmin;
      default:
        return null;
    }
  }

  String get label => switch (this) {
        AdminRole.viewer => 'Viewer',
        AdminRole.staff => 'Staff',
        AdminRole.admin => 'Admin',
        AdminRole.superAdmin => 'Super Admin',
      };

  /// Whether this role may mutate products, orders and tickets.
  bool get canManage => index >= AdminRole.staff.index;
}

/// Authenticated administrator profile, resolved from Firestore.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      other is AdminUser && other.id == id && other.role == role;

  @override
  int get hashCode => Object.hash(id, role);
}

/// Result of an admin sign-in attempt.
enum AdminLoginResult { success, invalidCredentials, notAuthorised, failed }

/// Signs administrators in through Firebase Auth and authorises them against a
/// Firestore role document.
///
/// This replaces the previous client-side credential comparison. A password
/// compiled into the APK is recoverable by anyone who downloads it, so the
/// authoritative check must happen server-side (Firebase Auth + role doc).
class AdminAuthNotifier extends StateNotifier<AsyncValue<AdminUser?>> {
  AdminAuthNotifier(this._auth, this._firestore)
      : super(const AsyncValue.data(null));

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// UID of the account from the most recent `notAuthorised` sign-in attempt.
  ///
  /// The login screen surfaces this so the owner can provision the matching
  /// `admins/{uid}` document without digging through logs — an unprovisioned
  /// account is the most common reason the portal "does nothing".
  String? lastUnauthorisedUid;

  /// Admin emails allowed to sign in even before a role document exists.
  /// Each entry is a custom claim or a seeded Firestore role in production.
  static const Set<String> _bootstrapAdmins = {};

  Future<AdminLoginResult> login(String email, String password) async {
    lastUnauthorisedUid = null;
    state = const AsyncValue.loading();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        state = const AsyncValue.data(null);
        return AdminLoginResult.failed;
      }

      final admin = await _loadAdminProfile(user);
      if (admin == null) {
        // Authenticated, but not an administrator: sign back out so the
        // customer app's session is not left in a half-privileged state.
        lastUnauthorisedUid = user.uid;
        await _auth.signOut();
        state = const AsyncValue.data(null);
        return AdminLoginResult.notAuthorised;
      }

      state = AsyncValue.data(admin);
      AdminAlertService.instance.start();
      AppLogger.info('Admin signed in', tag: 'admin_auth', context: {
        'uid': admin.id,
        'role': admin.role.name,
      });
      return AdminLoginResult.success;
    } on FirebaseAuthException catch (e) {
      state = const AsyncValue.data(null);
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return AdminLoginResult.invalidCredentials;
      }
      state = AsyncValue.error(ErrorMapper.map(e, StackTrace.current),
          StackTrace.current);
      return AdminLoginResult.failed;
    } catch (e, st) {
      AppLogger.error('Admin sign-in failed', tag: 'admin_auth', error: e);
      state = AsyncValue.error(ErrorMapper.map(e, st), st);
      return AdminLoginResult.failed;
    }
  }

  /// Resolves the admin profile from the custom claim or the `admins`
  /// collection. Returns null when the user holds no administrative role.
  Future<AdminUser?> _loadAdminProfile(User user) async {
    final token = await user.getIdTokenResult(true);
    final claimRole = AdminRole.tryParse(token.claims?['role'] as String?);
    if (claimRole != null) {
      return AdminUser(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email ?? 'Administrator',
        role: claimRole,
        createdAt: user.metadata.creationTime,
      );
    }

    final doc =
        await _firestore.collection('admins').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      if (_bootstrapAdmins.contains(user.email?.toLowerCase())) {
        return AdminUser(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Administrator',
          role: AdminRole.admin,
          createdAt: user.metadata.creationTime,
        );
      }
      return null;
    }

    final data = doc.data()!;
    final role = AdminRole.tryParse(data['role'] as String?);
    if (role == null) return null;

    return AdminUser(
      id: user.uid,
      email: (data['email'] as String?) ?? user.email ?? '',
      name: (data['name'] as String?) ??
          user.displayName ??
          'Administrator',
      role: role,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<void> logout() async {
    await AdminAlertService.instance.stop();
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }

  /// Restores an admin session from a persisted Firebase Auth user, e.g. after
  /// the app is relaunched. Returns false when the user is not an administrator.
  Future<bool> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      state = const AsyncValue.data(null);
      return false;
    }

    state = const AsyncValue.loading();
    try {
      final admin = await _loadAdminProfile(user);
      if (admin == null) {
        await _auth.signOut();
        state = const AsyncValue.data(null);
        return false;
      }
      state = AsyncValue.data(admin);
      AdminAlertService.instance.start();
      return true;
    } catch (e, st) {
      AppLogger.error('Admin session restore failed',
          tag: 'admin_auth', error: e);
      state = AsyncValue.error(ErrorMapper.map(e, st), st);
      return false;
    }
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AsyncValue<AdminUser?>>((ref) {
  return AdminAuthNotifier(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

/// The signed-in administrator, or null. Safe to `watch` from widgets.
final currentAdminProvider = Provider<AdminUser?>((ref) {
  return ref.watch(adminAuthProvider).valueOrNull;
});

/// True when an administrator is signed in and holds a mutating role.
final isAdminLoggedInProvider = Provider<bool>((ref) {
  final admin = ref.watch(currentAdminProvider);
  return admin != null && admin.role.canManage;
});

/// Guards a privileged action, throwing a typed error when the caller lacks
/// the required role. Pass the current admin so it works from either a `Ref`
/// or a `WidgetRef`:
///
/// ```dart
/// final admin = requireAdmin(ref.read(currentAdminProvider));
/// ```
AdminUser requireAdmin(
  AdminUser? admin, {
  AdminRole minimum = AdminRole.staff,
}) {
  if (admin == null) {
    throw const AuthException(
      message: 'You must be signed in as an administrator.',
      code: 'admin-required',
    );
  }
  if (admin.role.index < minimum.index) {
    throw AuthException(
      message: 'Your role (${admin.role.label}) cannot perform this action.',
      code: 'insufficient-role',
    );
  }
  return admin;
}

/// Firestore handle shared by the admin controllers.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});
