import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/core/constants/payment_constants.dart';

void main() {
  group('PaymentConstants', () {
    test('exposes the shop payment account', () {
      expect(PaymentConstants.bankName, 'Opay');
      expect(PaymentConstants.accountNumber, '8137843441');
      expect(PaymentConstants.accountName, 'Bassey Victoria Oluwakemi');
    });

    test('converts the local WhatsApp number to wa.me international form', () {
      final uri = PaymentConstants.whatsappUri();
      expect(uri.host, 'wa.me');
      expect(uri.path, '/2348137843441');
    });

    test('pre-fills the order reference and amount', () {
      final uri = PaymentConstants.whatsappUri(
        orderId: 'ABC123',
        amount: '25000',
      );
      final text = uri.queryParameters['text']!;
      expect(text, contains('order #ABC123'));
      expect(text, contains('₦25000'));
    });

    test('omits the order line when there is no order yet', () {
      final uri = PaymentConstants.whatsappUri(amount: '5000');
      final text = uri.queryParameters['text']!;
      expect(text, isNot(contains('order #')));
      expect(text, contains('₦5000'));
    });
  });
}
