import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fabric_haven/core/theme/app_colors.dart';
import 'package:fabric_haven/presentation/screens/splash_screen.dart';

/// The splash must render its full brand block on the smallest phones we
/// support and on tablets, with no overflow, and must dispose its animation
/// controllers cleanly.
void main() {
  Future<void> pumpSplash(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SplashScreen())),
    );
    await tester.pump(const Duration(milliseconds: 1500));
  }

  testWidgets('renders the gradient, brand block and feature pills',
      (tester) async {
    await pumpSplash(tester, const Size(390, 844));

    expect(find.text('Victoria Fabrics'), findsOneWidget);
    expect(
      find.text('Premium Ankara, Lace & Cotton, delivered.'),
      findsOneWidget,
    );
    expect(find.text('Handpicked Prints'), findsOneWidget);
    expect(find.text('Quality Assured'), findsOneWidget);
    expect(find.text('Fast Delivery'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.diamond_rounded), findsOneWidget);

    // The hero gradient is the background, not a purple leftover.
    expect(AppColors.primary, const Color(0xFF0A6847));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('fits a 320x568 phone without overflow', (tester) async {
    await pumpSplash(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(find.text('Victoria Fabrics'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('fits a tablet without overflow', (tester) async {
    await pumpSplash(tester, const Size(1024, 1366));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
