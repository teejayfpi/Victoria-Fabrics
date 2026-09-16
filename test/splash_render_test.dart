import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fabric_haven/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('splash renders the hero photograph', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SplashScreen())),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 1600));

    // The hero photo must be the real asset, not the error fallback.
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, isNotEmpty, reason: 'splash hero image should be present');
    final asset = images.first.image;
    expect(asset, isA<AssetImage>());
    expect((asset as AssetImage).assetName, 'assets/images/splash.jpg');

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
