import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/product.dart';

/// Builds a single order line item from an authoritative product document.
///
/// Pure, so the price and line-total derivation is unit-testable without
/// Firebase. This mirrors the derivation the security rules and the
/// `placeOrder` Cloud Function apply — the client never supplies a price.
Map<String, dynamic> buildOrderLineItem({
  required Product product,
  required CartItem item,
}) {
  final unitPrice = product.getPrice(item.selectedUnit);
  return {
    'productId': product.id,
    'productName': product.name,
    'imageUrl': product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
    'quantity': item.quantity,
    'selectedUnit': item.selectedUnit,
    'unitPrice': unitPrice,
    'totalPrice': unitPrice * item.quantity,
  };
}

/// Sums the line totals, rounding to two decimals to avoid float drift.
double orderTotal(List<Map<String, dynamic>> lineItems) {
  final total = lineItems.fold<double>(
    0,
    (sum, item) => sum + (item['totalPrice'] as num).toDouble(),
  );
  return double.parse(total.toStringAsFixed(2));
}

/// Maximum number of distinct lines in one order. Mirrors the ceiling in
/// `firestore.rules`, which cannot loop over items and therefore unrolls the
/// per-line validation.
const int kMaxOrderLines = 10;

/// Builds the Firestore document for a new order.
///
/// [userId] must be the signed-in uid, or null for a guest order — the security
/// rules reject a mismatch. `createdAt` uses a server timestamp so ordering is
/// consistent regardless of the device clock.
Map<String, dynamic> buildOrderDocument({
  required String shortId,
  required String? userId,
  required List<Map<String, dynamic>> lineItems,
  required double totalAmount,
  required DeliveryType deliveryType,
  String? deliveryAddress,
  String? pickupLocation,
  required String customerName,
  required String customerPhone,
}) {
  if (lineItems.isEmpty) {
    throw ArgumentError('An order must contain at least one item');
  }
  if (lineItems.length > kMaxOrderLines) {
    throw ArgumentError(
      'An order may contain at most $kMaxOrderLines different items',
    );
  }
  return {
    'id': shortId,
    if (userId != null) 'userId': userId,
    'items': lineItems,
    'totalAmount': totalAmount,
    'deliveryType':
        deliveryType == DeliveryType.delivery ? 'delivery' : 'pickup',
    'deliveryAddress': deliveryAddress,
    'pickupLocation': pickupLocation,
    'status': OrderStatus.pending.name,
    'createdAt': FieldValue.serverTimestamp(),
    'customerName': customerName,
    'customerPhone': customerPhone,
  };
}
