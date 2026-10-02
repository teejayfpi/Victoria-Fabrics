import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

/// Store information the owner publishes from the admin portal: the shop
/// address, opening contact details and the current delivery fee.
///
/// Everything here comes from the live `settings/store` document, so an owner
/// edit appears without a new build.
class StoreInfoScreen extends ConsumerWidget {
  const StoreInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(storeSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Information')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  settings.storeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your neighbourhood fabric store',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            icon: Icons.location_on_outlined,
            title: 'Shop address',
            lines: [
              settings.addressLine.isEmpty
                  ? settings.storeName
                  : settings.addressLine,
              if (settings.city.isNotEmpty) settings.city,
              if (settings.state.isNotEmpty) settings.state,
            ],
            actionLabel: settings.formattedAddress.isEmpty ? null : 'Open in Maps',
            onAction: () => _openMap(context, settings.formattedAddress),
          ),
          _InfoCard(
            icon: Icons.phone_outlined,
            title: 'Phone',
            lines: [settings.contactPhone],
            actionLabel: 'Call',
            onAction: () => _launch(
              context,
              Uri(scheme: 'tel', path: settings.contactPhone),
            ),
          ),
          _InfoCard(
            icon: Icons.chat_outlined,
            title: 'WhatsApp',
            lines: [settings.contactWhatsapp],
            actionLabel: 'Message',
            onAction: () => _launch(context, _whatsappUri(settings.contactWhatsapp)),
          ),
          if (settings.contactEmail.isNotEmpty)
            _InfoCard(
              icon: Icons.email_outlined,
              title: 'Email',
              lines: [settings.contactEmail],
              actionLabel: 'Email',
              onAction: () => _launch(
                context,
                Uri(scheme: 'mailto', path: settings.contactEmail),
              ),
            ),
          _InfoCard(
            icon: Icons.local_shipping_outlined,
            title: 'Delivery',
            lines: [
              if (!settings.deliveryEnabled)
                'Delivery is currently unavailable.'
              else if (settings.deliveryFee == 0)
                'Free delivery on all orders.'
              else
                'Flat fee of ${settings.deliveryFee.toStringAsFixed(0)} '
                    'per delivery order.',
              if (settings.pickupEnabled) 'Pickup available at the shop.',
            ],
          ),
        ],
      ),
    );
  }

  Uri _whatsappUri(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final intl = digits.startsWith('0')
        ? '234${digits.substring(1)}'
        : digits.startsWith('234')
            ? digits
            : '234$digits';
    return Uri.parse('https://wa.me/$intl');
  }

  Future<void> _openMap(BuildContext context, String address) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    await _launch(context, uri);
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the app.')),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.lines,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final shown = lines.where((l) => l.trim().isNotEmpty).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  for (final line in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(line,
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                  if (actionLabel != null && onAction != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(actionLabel!),
                      ),
                    ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null)
              IconButton(
                tooltip: actionLabel,
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shown.join(', ')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
