import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/data/mappers/place_order_payload.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/order.dart';
import 'package:fabric_haven/domain/entities/product.dart';

Product _product() => const Product(
      id: 'p1',
      name: 'Royal Ankara',
      description: 'Premium wax print',
      categoryId: 'ankara',
      categoryName: 'Ankara',
      imageUrls: ['https://example.com/a.jpg'],
      pricePerYard: 5000,
      pricePerMeter: 5500,
      pricePerPiece: 12000,
      inStock: true,
      colors: ['Red'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    );

CartItem _item({int quantity = 2, String unit = 'Yard'}) => CartItem(
      product: _product(),
      quantity: quantity,
      selectedUnit: unit,
    );

void main() {
  group('buildPlaceOrderPayload', () {
    test('sends only intent — product id, quantity and unit', () {
      final payload = buildPlaceOrderPayload(
        items: [_item()],
        expectedTotal: 10000,
        deliveryType: DeliveryType.delivery,
        deliveryAddress: '12 Broad St',
        customerName: 'Ada',
        customerPhone: '+2348000000000',
      );

      expect(payload['items'], [
        {'productId': 'p1', 'quantity': 2, 'selectedUnit': 'Yard'},
      ]);
      expect(payload['expectedTotal'], 10000);
      expect(payload['deliveryType'], 'delivery');
      expect(payload['deliveryAddress'], '12 Broad St');
      expect(payload['customerName'], 'Ada');
      expect(payload['customerPhone'], '+2348000000000');
    });

    test('never sends client-side price or stock fields', () {
      final payload = buildPlaceOrderPayload(
        items: [_item()],
        expectedTotal: 10000,
        deliveryType: DeliveryType.pickup,
        customerName: 'Ada',
        customerPhone: '+2348000000000',
      );

      final item = (payload['items'] as List).single as Map;
      expect(item.containsKey('unitPrice'), isFalse);
      expect(item.containsKey('totalPrice'), isFalse);
      expect(item.containsKey('stockCount'), isFalse);
    });

    test('omits deliveryAddress for pickup and null optionals', () {
      final payload = buildPlaceOrderPayload(
        items: [_item()],
        expectedTotal: 10000,
        deliveryType: DeliveryType.pickup,
        customerName: 'Ada',
        customerPhone: '+2348000000000',
      );

      expect(payload.containsKey('deliveryAddress'), isFalse);
      expect(payload.containsKey('pickupLocation'), isFalse);
      expect(payload['deliveryType'], 'pickup');
    });

    test('maps every cart line in order', () {
      final payload = buildPlaceOrderPayload(
        items: [_item(quantity: 1), _item(quantity: 3, unit: 'Meter')],
        expectedTotal: 21500,
        deliveryType: DeliveryType.delivery,
        deliveryAddress: '12 Broad St',
        customerName: 'Ada',
        customerPhone: '+2348000000000',
      );

      final items = payload['items'] as List;
      expect(items.length, 2);
      expect(items[0], {'productId': 'p1', 'quantity': 1, 'selectedUnit': 'Yard'});
      expect(
        items[1],
        {'productId': 'p1', 'quantity': 3, 'selectedUnit': 'Meter'},
      );
    });
  });
}
