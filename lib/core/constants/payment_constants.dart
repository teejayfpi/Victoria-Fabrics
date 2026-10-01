class PaymentConstants {
  static const String bankName = 'Opay';
  static const String accountNumber = '8137843441';
  static const String accountName = 'Bassey Victoria Oluwakemi';
  static const String paymentInstructions =
      'Transfer the exact total amount to the account details below. '
      'Your order will be confirmed once payment is received.';

  /// Customer-facing support / payment-confirmation line. Stored in local
  /// format so it can also be shown as text; [whatsappUri] converts it to the
  /// international form wa.me requires.
  static const String whatsappNumber = '08137843441';
  static const String whatsappDisplay = '0813 784 3441';

  /// Builds a wa.me link with the order reference pre-filled, so the customer
  /// only has to attach their transfer receipt.
  static Uri whatsappUri({String? orderId, String? amount}) {
    final lines = <String>[
      'Hello Victoria Fabrics,',
      if (orderId != null && orderId.isNotEmpty)
        'I have made payment for order #$orderId.',
      if (amount != null && amount.isNotEmpty) 'Amount paid: ₦$amount.',
      'Here is my payment receipt.',
    ];
    final text = Uri.encodeComponent(lines.join('\n'));
    return Uri.parse('https://wa.me/$_whatsappIntl?text=$text');
  }

  static Uri get whatsappChatUri =>
      Uri.parse('https://wa.me/$_whatsappIntl');

  /// Nigerian local numbers are 0XXXXXXXXXX; wa.me wants 234XXXXXXXXXX.
  static String get _whatsappIntl {
    final digits = whatsappNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return '234${digits.substring(1)}';
    if (digits.startsWith('234')) return digits;
    return '234$digits';
  }
}
