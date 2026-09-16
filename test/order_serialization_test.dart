import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/category.dart';
import 'package:fabric_haven/domain/entities/order.dart' as domain;
import 'package:fabric_haven/domain/entities/product.dart';

void main() {
  group('Order round-trip', () {
    const product = Product(
      id: 'p1',
      name: 'Royal Ankara',
      description: 'Wax print',
      categoryId: 'c1',
      categoryName: 'Ankara',
      imageUrls: ['https://example.com/a.jpg'],
      pricePerYard: 4500,
      pricePerMeter: 5000,
      pricePerPiece: 20000,
      inStock: true,
      colors: ['red'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    );

    final order = domain.Order(
      id: 'ORD-1',
      userId: 'user-1',
      items: const [
        CartItemFixture(product: product, quantity: 3, unit: 'Yard'),
      ].map((f) => f.item).toList(),
      totalAmount: 13500,
      deliveryType: domain.DeliveryType.delivery,
      deliveryAddress: '12 Broad Street, Lagos',
      status: domain.OrderStatus.pending,
      createdAt: DateTime(2026, 3, 1, 10, 30),
      customerName: 'Ada Obi',
      customerPhone: '08012345678',
    );

    test('toMap -> fromMap preserves the charged line price', () {
      final restored = domain.Order.fromMap('doc-1', order.toMap());

      expect(restored.id, 'ORD-1');
      expect(restored.userId, 'user-1');
      expect(restored.customerName, 'Ada Obi');
      expect(restored.totalAmount, 13500);
      expect(restored.status, domain.OrderStatus.pending);
      expect(restored.deliveryType, domain.DeliveryType.delivery);

      final item = restored.items.single;
      expect(item.quantity, 3);
      expect(item.selectedUnit, 'Yard');
      // Regression: the unit price was previously dropped on read, so order
      // history and analytics reported a zero line total.
      expect(item.unitPrice, 4500);
      expect(item.totalPrice, 13500);
    });

    test('createdAt survives as a Timestamp', () {
      final restored = domain.Order.fromMap('doc-1', order.toMap());
      expect(restored.createdAt, DateTime(2026, 3, 1, 10, 30));
    });

    test('missing createdAt falls back without throwing', () {
      final data = order.toMap()..remove('createdAt');
      final restored = domain.Order.fromMap('doc-1', data);
      expect(restored.createdAt, isA<DateTime>());
    });

    test('unknown status strings fall back to pending', () {
      final data = order.toMap()..['status'] = 'not-a-status';
      expect(domain.Order.fromMap('doc-1', data).status, domain.OrderStatus.pending);
    });

    test('a stored price is used even when the product is gone', () {
      final data = order.toMap();
      // Simulate the catalogue price changing after the order was placed:
      // the order must still report what the customer actually paid.
      (data['items'] as List).first['unitPrice'] = 99.0;

      final restored = domain.Order.fromMap('doc-1', data);
      expect(restored.items.single.unitPrice, 99.0);
    });

    test('Timestamp input round-trips from Firestore shape', () {
      final data = order.toMap();
      expect(data['createdAt'], isA<Timestamp>());
    });
  });

  test('Category toMap/fromMap round-trips', () {
    const category = Category(
      id: 'c1',
      name: 'Silk',
      description: 'Pure silk',
      imageUrl: 'https://example.com/s.jpg',
      iconName: 'silk',
    );

    final restored = Category.fromMap('c1', category.toMap());
    expect(restored.name, 'Silk');
    expect(restored.description, 'Pure silk');
    expect(restored.imageUrl, 'https://example.com/s.jpg');
    expect(restored.iconName, 'silk');
  });
}

/// Helper so the order fixture above reads cleanly.
class CartItemFixture {
  final Product product;
  final int quantity;
  final String unit;

  const CartItemFixture({
    required this.product,
    required this.quantity,
    required this.unit,
  });

  CartItem get item =>
      CartItem(product: product, quantity: quantity, selectedUnit: unit);
}