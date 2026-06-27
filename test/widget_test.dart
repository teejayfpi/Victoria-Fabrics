import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fabric_haven/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FabricHavenApp(),
      ),
    );

    // Verify the app title is shown
    expect(find.text('Fabric Haven'), findsOneWidget);
  });
}