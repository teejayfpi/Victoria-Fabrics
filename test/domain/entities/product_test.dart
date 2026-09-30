import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/product.dart';

Product _product({
  double yard = 5000,
  double meter = 5500,
  double piece = 12000,
}) {
  return Product(
    id: 'p1',
    name: 'Royal Ankara',
    description: 'Premium wax print',
    categoryId: 'ankara',
    categoryName: 'Ankara',
    imageUrls: const ['https://example.com/a.jpg'],
    pricePerYard: yard,
    pricePerMeter: meter,
    pricePerPiece: piece,
    inStock: true,
    colors: const ['Red'],
    availableUnits: const ['Yard', 'Meter', 'Piece'],
  );
}

void main() {
  group('Product.getPrice', () {
    test('resolves the price for each unit, case-insensitively', () {
      final product = _product();
      expect(product.getPrice('Yard'), 5000);
      expect(product.getPrice('meter'), 5500);
      expect(product.getPrice('PIECE'), 12000);
    });

    test('falls back to the yard price for unknown units', () {
      expect(_product().getPrice('roll'), 5000);
    });
  });

  group('CartItem', () {
    test('uses the live catalogue price when no override is set', () {
      final item = CartItem(
        product: _product(),
        quantity: 3,
        selectedUnit: 'Yard',
      );

      expect(item.unitPrice, 5000);
      expect(item.totalPrice, 15000);
    });

    test('prefers the captured unit price override', () {
      final item = CartItem(
        product: _product(),
        quantity: 2,
        selectedUnit: 'Yard',
        unitPriceOverride: 4200,
      );

      expect(item.unitPrice, 4200);
      expect(item.totalPrice, 8400);
    });

    test('copyWith keeps unrelated fields', () {
      final item = CartItem(
        product: _product(),
        quantity: 1,
        selectedUnit: 'Meter',
      );

      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.selectedUnit, 'Meter');
      expect(updated.product.id, 'p1');
    });
  });

  group('Product round-trip', () {
    test('survives toMap/fromMap serialisation', () {
      final original = _product();
      final restored = Product.fromMap('p1', original.toMap());

      expect(restored.id, 'p1');
      expect(restored.name, original.name);
      expect(restored.pricePerYard, original.pricePerYard);
      expect(restored.categoryName, original.categoryName);
    });
  });
}
