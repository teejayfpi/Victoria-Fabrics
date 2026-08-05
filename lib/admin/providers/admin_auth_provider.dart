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

// Admin credentials — change these to your preferred credentials
const String _adminEmail = 'admin@victoriafabrics.com';
const String _adminPassword = 'Victoria@2024';

class AdminAuthNotifier extends StateNotifier<AdminUser?> {
  AdminAuthNotifier() : super(null);

  Future<bool> login(String email, String password) async {
    // Simulate a brief network call
    await Future.delayed(const Duration(milliseconds: 500));

    if (email.trim().toLowerCase() == _adminEmail &&
        password == _adminPassword) {
      state = AdminUser(
        id: 'admin_001',
        email: email,
        name: 'Store Admin',
        role: 'super_admin',
        createdAt: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  void logout() {
    state = null;
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminUser?>((ref) {
  return AdminAuthNotifier();
});

final isAdminLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthProvider) != null;
});
