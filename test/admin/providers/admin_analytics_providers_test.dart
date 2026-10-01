import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/admin/providers/admin_analytics_providers.dart';
import 'package:fabric_haven/admin/providers/admin_data_providers.dart';
import 'package:fabric_haven/domain/entities/cart_item.dart';
import 'package:fabric_haven/domain/entities/order.dart';
import 'package:fabric_haven/domain/entities/product.dart';

Product _product(String id, String category) => Product(
      id: id,
      name: 'Fabric $id',
      description: 'desc',
      categoryId: category,
      categoryName: category,
      imageUrls: const [],
      pricePerYard: 1000,
      pricePerMeter: 1000,
      pricePerPiece: 1000,
      inStock: true,
      colors: const [],
      availableUnits: const ['Yard'],
    );

AdminOrder _order({
  required String id,
  required DateTime createdAt,
  required double total,
  required String customerName,
  OrderStatus status = OrderStatus.confirmed,
  String? userId,
  List<CartItem>? items,
}) {
  return AdminOrder(
    firestoreId: id,
    order: Order(
      id: id,
      userId: userId,
      items: items ??
          [
            CartItem(
              product: _product('p1', 'Ankara'),
              quantity: 2,
              selectedUnit: 'Yard',
              unitPriceOverride: total / 2,
            ),
          ],
      totalAmount: total,
      deliveryType: DeliveryType.delivery,
      status: status,
      createdAt: createdAt,
      customerName: customerName,
      customerPhone: '08000000000',
    ),
  );
}

/// Wires the analytics summary to a fixed list of orders, bypassing Firestore.
///
/// Streams emit asynchronously, so callers must `await` the returned future
/// (which resolves once the first value is available) before reading the
/// synchronous [analyticsSummaryProvider].
Future<ProviderContainer> _container(List<AdminOrder> orders) async {
  final container = ProviderContainer(
    overrides: [
      adminOrdersProvider.overrideWith((ref) => Stream.value(orders)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(adminOrdersProvider.future);
  return container;
}

void main() {
  group('analyticsSummaryProvider', () {
    test('aggregates revenue, orders and units within the window', () async {
      // Anchor the orders to the first of the current month rather than
      // "N days ago": near the start of a month, subtracting days falls into
      // the previous month and out of the window, which made this test
      // pass or fail depending on the calendar date.
      final now = DateTime.now();
      final firstOfMonth = DateTime(now.year, now.month, 1);
      final container = await _container([
        _order(
            id: 'a',
            createdAt: firstOfMonth.add(const Duration(hours: 1)),
            total: 10000,
            customerName: 'Ada'),
        _order(
            id: 'b',
            createdAt: firstOfMonth.add(const Duration(hours: 2)),
            total: 5000,
            customerName: 'Bola'),
      ]);

      container.read(analyticsRangeProvider.notifier).state =
          AnalyticsRange.month;

      final summary = container.read(analyticsSummaryProvider);
      expect(summary.orderCount, 2);
      expect(summary.totalRevenue, 15000);
      expect(summary.unitsSold, 4);
      expect(summary.averageOrderValue, 7500);
      expect(summary.uniqueCustomers, 2);
    });

    test('excludes cancelled orders and orders outside the range', () async {
      final now = DateTime.now();
      final container = await _container([
        _order(
            id: 'cancelled',
            createdAt: now,
            total: 9999,
            customerName: 'Cancelled',
            status: OrderStatus.cancelled),
        _order(
            id: 'old',
            createdAt: DateTime(now.year - 1, 1, 1),
            total: 9999,
            customerName: 'Old'),
        _order(
            id: 'valid',
            createdAt: now,
            total: 4000,
            customerName: 'Valid'),
      ]);

      container.read(analyticsRangeProvider.notifier).state =
          AnalyticsRange.today;

      final summary = container.read(analyticsSummaryProvider);
      expect(summary.orderCount, 1);
      expect(summary.totalRevenue, 4000);
    });

    test('counts a signed-in customer once across multiple orders', () async {
      final now = DateTime.now();
      final container = await _container([
        _order(
            id: 'o1',
            createdAt: now,
            total: 1000,
            customerName: 'Ada',
            userId: 'uid-1'),
        _order(
            id: 'o2',
            createdAt: now,
            total: 1000,
            customerName: 'Ada',
            userId: 'uid-1'),
      ]);

      container.read(analyticsRangeProvider.notifier).state =
          AnalyticsRange.today;

      expect(container.read(analyticsSummaryProvider).uniqueCustomers, 1);
    });

    test('returns an empty summary when nothing falls in range', () async {
      final container = await _container([]);
      container.read(analyticsRangeProvider.notifier).state =
          AnalyticsRange.today;

      final summary = container.read(analyticsSummaryProvider);
      expect(summary.orderCount, 0);
      expect(summary.totalRevenue, 0);
      expect(summary.topProducts, isEmpty);
    });
  });

  group('AnalyticsRange.startFrom', () {
    test('today starts at midnight', () {
      final start = AnalyticsRange.today.startFrom(DateTime(2026, 9, 30, 15));
      expect(start, DateTime(2026, 9, 30));
    });

    test('month starts on the first of the month', () {
      final start = AnalyticsRange.month.startFrom(DateTime(2026, 9, 30, 15));
      expect(start, DateTime(2026, 9, 1));
    });

    test('year starts on January 1st', () {
      final start = AnalyticsRange.year.startFrom(DateTime(2026, 9, 30, 15));
      expect(start, DateTime(2026, 1, 1));
    });
  });

  group('AdminOrder.fromRow', () {
    test('keeps the Firestore document id alongside the display reference', () {
      final adminOrder = AdminOrder.fromRow({
        'firestoreId': 'doc123',
        'id': 'ABC12345',
        'items': const [],
        'totalAmount': 100,
        'deliveryType': 'pickup',
        'status': 'pending',
        'createdAt': DateTime(2026, 1, 1),
        'customerName': 'Ada',
        'customerPhone': '08000000000',
      });

      expect(adminOrder.firestoreId, 'doc123');
      expect(adminOrder.order.id, 'ABC12345');
      expect(adminOrder.order.reference, 'VF-ABC12345');
    });
  });
}
