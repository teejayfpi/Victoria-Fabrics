import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/category.dart';
import 'package:fabric_haven/domain/entities/product.dart';
import 'package:fabric_haven/presentation/widgets/cart_item_widget.dart';
import 'package:fabric_haven/presentation/widgets/category_card.dart';
import 'package:fabric_haven/presentation/widgets/product_card.dart';

Product _product({String name = 'Royal Ankara', bool inStock = true}) =>
    Product(
      id: 'p1',
      name: name,
      description: '',
      categoryId: 'ankara',
      categoryName: 'Ankara',
      imageUrls: const [],
      pricePerYard: 5000,
      pricePerMeter: 5500,
      pricePerPiece: 12000,
      inStock: inStock,
      colors: const [],
      availableUnits: const ['Yard', 'Meter', 'Piece'],
      stockCount: 12,
    );

const _category = Category(
  id: 'c1',
  name: 'Ankara',
  description: 'Premium wax print',
  imageUrl: '',
  iconName: 'checkroom',
);

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );

void main() {
  // A RenderFlex overflow raises an exception during pump, failing the test,
  // so these double as regression guards against clipped layouts.
  final sizes = <String, Size>{
    'small phone': const Size(320, 568),
    'standard phone': const Size(390, 844),
    'tablet': const Size(1024, 1366),
  };

  for (final entry in sizes.entries) {
    testWidgets('ProductCard lays out on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 180,
            height: 260,
            child: ProductCard(
              product: _product(),
              onTap: () {},
              onAddToCart: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('ProductCard (out of stock) lays out on ${entry.key}',
        (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 180,
            height: 260,
            child: ProductCard(
              product: _product(inStock: false),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoryCard lays out on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 200,
            height: 160,
            child: CategoryCard(category: _category, onTap: () {}),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('CartItemWidget lays out on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          CartItemWidget(
            item: CartItem(
              product: _product(
                name: 'Premium Ankara Wax Print With A Very Long Name',
              ),
              quantity: 3,
              selectedUnit: 'Yard',
            ),
            onIncrement: () {},
            onDecrement: () {},
            onRemove: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
