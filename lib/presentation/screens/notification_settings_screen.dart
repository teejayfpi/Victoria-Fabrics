import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/user_profile_provider.dart';

/// Customer-facing notification preferences, persisted on `users/{uid}`.
///
/// These are app-level toggles. OS delivery still depends on the Android 13+
/// permission requested at startup; the banner below surfaces that state so a
/// disabled toggle is not mistaken for a bug.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userProfileValueProvider).notifications;
    final controller = ref.read(userDataControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          const _InfoBanner(),
          SwitchListTile(
            secondary: const Icon(Icons.local_shipping_outlined),
            title: const Text('Order updates'),
            subtitle: const Text('Status changes for your orders'),
            value: prefs.orderUpdates,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (v) => controller.updateNotificationPreferences(
              prefs.copyWith(orderUpdates: v),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.support_agent_outlined),
            title: const Text('Support replies'),
            subtitle: const Text('When we respond to your ticket'),
            value: prefs.supportReplies,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (v) => controller.updateNotificationPreferences(
              prefs.copyWith(supportReplies: v),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.local_offer_outlined),
            title: const Text('Promotions'),
            subtitle: const Text('Offers and new arrivals'),
            value: prefs.promotions,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (v) => controller.updateNotificationPreferences(
              prefs.copyWith(promotions: v),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Turning these off stops the app from raising notifications. '
              'Your phone\'s system settings may also need to allow them.',
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
