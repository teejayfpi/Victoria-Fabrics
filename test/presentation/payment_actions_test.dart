import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/presentation/widgets/payment_actions.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );

void main() {
  // A RenderFlex overflow raises during pump, so these fail loudly if the
  // payment block stops fitting — on a 320pt phone the two buttons and their
  // labels are the tightest case.
  final sizes = <String, Size>{
    'small phone': const Size(320, 568),
    'standard phone': const Size(390, 844),
    'tablet': const Size(1024, 1366),
  };

  for (final entry in sizes.entries) {
    testWidgets('PaymentActions lays out on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          const Padding(
            padding: EdgeInsets.all(16),
            child: PaymentActions(orderId: 'ABC123', amount: '25000'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('WhatsApp'), findsOneWidget);
    });

    testWidgets('PaymentActions with the short label lays out on ${entry.key}',
        (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          const Padding(
            padding: EdgeInsets.all(16),
            child: PaymentActions(whatsappLabel: 'Message us on WhatsApp'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
