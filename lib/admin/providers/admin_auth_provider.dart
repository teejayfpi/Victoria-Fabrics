import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AdminAuthNotifier extends StateNotifier<AdminUser?> {
  AdminAuthNotifier() : super(null) {
    _initDemoAdmin();
  }

  void _initDemoAdmin() {
    // Demo mode - simulate logged in admin
    state = AdminUser(
      id: 'admin_001',
      email: 'admin@fabrichaven.com',
      name: 'Store Admin',
      role: 'super_admin',
      createdAt: DateTime.now(),
    );
  }

  Future<bool> login(String email, String password) async {
    // Demo mode - accept any credentials
    if (email.isNotEmpty && password.isNotEmpty) {
      state = AdminUser(
        id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: email.split('@').first,
        role: 'admin',
        createdAt: DateTime.now(),
      );
      print('[Admin] Logged in as: $email');
      return true;
    }
    return false;
  }

  void logout() {
    state = null;
    print('[Admin] Logged out');
  }
}

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, AdminUser?>((ref) {
  return AdminAuthNotifier();
});

final isAdminLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthProvider) != null;
});