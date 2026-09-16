import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../providers/admin_auth_provider.dart';

/// Branded launch screen for the admin app.
///
/// Mirrors the customer splash so both apps feel like one product, then
/// hands off to the dashboard or the login screen depending on whether an
/// admin session already exists.
class AdminSplashScreen extends ConsumerWidget {
  const AdminSplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wait for the persisted session to resolve before choosing a
    // destination; otherwise a returning admin is bounced to the login screen.
    final restored = ref.watch(adminSessionRestoreProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      restored.when(
        loading: () {},
        error: (_, __) => context.go('/admin/login'),
        data: (admin) =>
            context.go(admin == null ? '/admin/login' : '/admin'),
      );
    });

    return const Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdminLogoBadge(),
              SizedBox(height: 20),
              Text(
                'Victoria Fabrics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Admin Console',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminLogoBadge extends StatelessWidget {
  const _AdminLogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 2),
      ),
      child: const Icon(
        Icons.admin_panel_settings_rounded,
        size: 46,
        color: AppColors.accent,
      ),
    );
  }
}
