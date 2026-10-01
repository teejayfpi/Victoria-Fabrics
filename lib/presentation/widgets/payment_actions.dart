import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/payment_constants.dart';

/// Payment follow-up actions shown alongside the bank details: message the
/// shop on WhatsApp with the order reference pre-filled, or call the line.
///
/// The order is placed before payment, so this is the step that turns a
/// pending order into a confirmed one.
class PaymentActions extends StatelessWidget {
  const PaymentActions({
    super.key,
    this.orderId,
    this.amount,
    this.whatsappLabel = 'Send payment receipt on WhatsApp',
  });

  final String? orderId;
  final String? amount;
  final String whatsappLabel;

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open the app. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _open(
            context,
            PaymentConstants.whatsappUri(orderId: orderId, amount: amount),
          ),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(whatsappLabel),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _open(
            context,
            Uri(scheme: 'tel', path: PaymentConstants.whatsappNumber),
          ),
          icon: const Icon(Icons.call_outlined),
          label: const Text('Call ${PaymentConstants.whatsappDisplay}'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}
