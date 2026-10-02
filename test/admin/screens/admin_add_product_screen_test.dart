import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/admin/screens/admin_add_product_screen.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/domain/entities/category.dart';
import 'package:fabric_haven/presentation/providers/category_provider.dart';

const _categories = [
  Category(
    id: 'c1',
    name: 'Ankara',
    description: 'Wax print',
    imageUrl: '',
    iconName: 'checkroom',
  ),
  Category(
    id: 'c2',
    name: 'Lace',
    description: 'French lace',
    imageUrl: '',
    iconName: 'checkroom',
  ),
];

Widget _host(List<Category> categories) => ProviderScope(
      overrides: [
        categoriesStreamProvider
            .overrideWith((ref) => Stream.value(categories)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminAddProductScreen(),
      ),
    );

void main() {
  // Regression guard for the reported "category is not clickable" bug: the
  // picker must render a real, tappable dropdown once categories exist.
  testWidgets('category dropdown opens and selects a value', (tester) async {
    await tester.pumpWidget(_host(_categories));
    await tester.pumpAndSettle();

    expect(find.text('Category *'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // The menu lists every category; pick one.
    await tester.tap(find.text('Lace').last);
    await tester.pumpAndSettle();

    expect(find.text('Lace'), findsOneWidget);
  });

  testWidgets('shows a loading state while categories are pending',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesStreamProvider
              .overrideWith((ref) => const Stream<List<Category>>.empty()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminAddProductScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading categories…'), findsOneWidget);
  });

  testWidgets('explains how to recover when there are no categories',
      (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.text('No categories available'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
  });
}
