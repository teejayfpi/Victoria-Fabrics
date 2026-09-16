import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fabric_haven/core/theme/app_colors.dart';
import 'package:fabric_haven/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen shows the brand identity', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SplashScreen()),
      ),
    );

    // Animations settle; the hand-off timer never fires in this test.
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Victoria Fabrics'), findsOneWidget);
    expect(
        find.text('Premium Ankara, Lace & Cotton, delivered.'), findsOneWidget);
    expect(find.text('Welcome to Victoria Fabrics…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Splash screen uses the enterprise palette', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.body, isA<Stack>());
    expect(AppColors.primary, const Color(0xFF0A6847));
    expect(AppColors.accent, const Color(0xFFFFB800));

    // The enter animations must be disposed cleanly on teardown.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
