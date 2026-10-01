import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/data/mappers/order_document.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/order.dart';
import 'package:fabric_haven/domain/entities/product.dart';

Product _product({
  double yard = 5000,
  double meter = 5500,
  double piece = 12000,
}) =>
    Product(
      id: 'p1',
      name: 'Royal Ankara',
      description: '',
      categoryId: 'ankara',
      categoryName: 'Ankara',
      imageUrls: const ['https://example.com/a.jpg'],
      pricePerYard: yard,
      pricePerMeter: meter,
      pricePerPiece: piece,
      inStock: true,
      colors: const [],
      availableUnits: const ['Yard', 'Meter', 'Piece'],
      stockCount: 20,
    );

void main() {
  group('buildOrderLineItem', () {
    test('derives unit price and line total from the product, not the cart', () {
      final line = buildOrderLineItem(
        product: _product(),
        item: CartItem(
          product: _product(),
          quantity: 3,
          selectedUnit: 'Meter',
        ),
      );

      expect(line['productId'], 'p1');
      expect(line['unitPrice'], 5500);
      expect(line['totalPrice'], 16500);
      expect(line['quantity'], 3);
      expect(line['selectedUnit'], 'Meter');
      expect(line['imageUrl'], 'https://example.com/a.jpg');
    });

    test('ignores a stale cart price override', () {
      final line = buildOrderLineItem(
        product: _product(yard: 7000),
        item: CartItem(
          product: _product(yard: 5000),
          quantity: 1,
          selectedUnit: 'Yard',
          unitPriceOverride: 1,
        ),
      );

      // The authoritative product price wins, never the client override.
      expect(line['unitPrice'], 7000);
      expect(line['totalPrice'], 7000);
    });

    test('unknown unit falls back to the yard price', () {
      final line = buildOrderLineItem(
        product: _product(),
        item: CartItem(
          product: _product(),
          quantity: 1,
          selectedUnit: 'Furlong',
        ),
      );

      expect(line['unitPrice'], 5000);
    });
  });

  group('orderTotal', () {
    test('sums line totals', () {
      final total = orderTotal([
        {'totalPrice': 5000.0},
        {'totalPrice': 16500.0},
      ]);
      expect(total, 21500);
    });

    test('rounds floating point drift to two decimals', () {
      final total = orderTotal([
        {'totalPrice': 0.1},
        {'totalPrice': 0.2},
      ]);
      expect(total, 0.3);
    });

    test('empty order totals zero', () {
      expect(orderTotal([]), 0);
    });
  });

  group('buildOrderDocument', () {
    test('pins server-controlled fields', () {
      final doc = buildOrderDocument(
        shortId: 'ABC12345',
        userId: 'uid-1',
        lineItems: [
          {'productId': 'p1', 'quantity': 2, 'totalPrice': 10000.0},
        ],
        totalAmount: 10000,
        deliveryType: DeliveryType.delivery,
        deliveryAddress: '12 Broad St',
        customerName: 'Ada',
        customerPhone: '+2348000000000',
      );

      expect(doc['status'], 'pending');
      expect(doc['createdAt'], isA<FieldValue>());
      expect(doc['userId'], 'uid-1');
      expect(doc['deliveryType'], 'delivery');
      expect(doc['totalAmount'], 10000);
    });

    test('omits userId for guest orders and uses pickup', () {
      final doc = buildOrderDocument(
        shortId: 'ABC12345',
        userId: null,
        lineItems: [
          {'productId': 'p1', 'quantity': 1, 'totalPrice': 5000.0},
        ],
        totalAmount: 5000,
        deliveryType: DeliveryType.pickup,
        pickupLocation: 'Victoria Fabrics Store, Lagos',
        customerName: 'Ada',
        customerPhone: '+2348000000000',
      );

      expect(doc.containsKey('userId'), isFalse);
      expect(doc['deliveryType'], 'pickup');
      expect(doc['deliveryAddress'], isNull);
      expect(doc['pickupLocation'], 'Victoria Fabrics Store, Lagos');
    });

    test('rejects an order with no items', () {
      expect(
        () => buildOrderDocument(
          shortId: 'ABC12345',
          userId: 'uid-1',
          lineItems: const [],
          totalAmount: 0,
          deliveryType: DeliveryType.pickup,
          customerName: 'Ada',
          customerPhone: '+2348000000000',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects more lines than the rules accept', () {
      final tooMany = List.generate(
        kMaxOrderLines + 1,
        (i) => {'productId': 'p$i', 'quantity': 1, 'totalPrice': 1.0},
      );

      expect(
        () => buildOrderDocument(
          shortId: 'ABC12345',
          userId: 'uid-1',
          lineItems: tooMany,
          totalAmount: 1,
          deliveryType: DeliveryType.pickup,
          customerName: 'Ada',
          customerPhone: '+2348000000000',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
