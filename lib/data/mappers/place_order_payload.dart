import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';

/// Builds the request body for the `placeOrder` Cloud Function.
///
/// Kept as a pure function so the client/server contract is unit-testable
/// without touching Firebase. The server is authoritative for price, stock and
/// total; this only conveys intent.
Map<String, dynamic> buildPlaceOrderPayload({
  required List<CartItem> items,
  required double expectedTotal,
  required DeliveryType deliveryType,
  String? deliveryAddress,
  String? pickupLocation,
  required String customerName,
  required String customerPhone,
}) {
  return {
    'items': items
        .map((item) => {
              'productId': item.product.id,
              'quantity': item.quantity,
              'selectedUnit': item.selectedUnit,
            })
        .toList(),
    'expectedTotal': expectedTotal,
    'deliveryType': deliveryType == DeliveryType.delivery ? 'delivery' : 'pickup',
    if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
    if (pickupLocation != null) 'pickupLocation': pickupLocation,
    'customerName': customerName,
    'customerPhone': customerPhone,
  };
}
