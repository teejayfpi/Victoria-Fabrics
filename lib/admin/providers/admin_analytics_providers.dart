import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/order.dart';
import '../../presentation/providers/product_provider.dart';
import 'admin_data_providers.dart';

enum AnalyticsRange {
  today,
  week,
  month,
  year;

  String get label => switch (this) {
        AnalyticsRange.today => 'Today',
        AnalyticsRange.week => 'This Week',
        AnalyticsRange.month => 'This Month',
        AnalyticsRange.year => 'This Year',
      };

  /// Start of the window, relative to [now].
  DateTime startFrom(DateTime now) {
    switch (this) {
      case AnalyticsRange.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsRange.week:
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
      case AnalyticsRange.month:
        return DateTime(now.year, now.month, 1);
      case AnalyticsRange.year:
        return DateTime(now.year, 1, 1);
    }
  }
}

class TopProduct {
  const TopProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });

  final String name;
  final int unitsSold;
  final double revenue;
}

class CategoryShare {
  const CategoryShare({
    required this.category,
    required this.revenue,
    required this.share,
  });

  final String category;
  final double revenue;
  final double share;
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalRevenue,
    required this.orderCount,
    required this.unitsSold,
    required this.uniqueCustomers,
    required this.topProducts,
    required this.categoryShares,
  });

  final double totalRevenue;
  final int orderCount;
  final int unitsSold;
  final int uniqueCustomers;
  final List<TopProduct> topProducts;
  final List<CategoryShare> categoryShares;

  double get averageOrderValue =>
      orderCount == 0 ? 0 : totalRevenue / orderCount;

  static const empty = AnalyticsSummary(
    totalRevenue: 0,
    orderCount: 0,
    unitsSold: 0,
    uniqueCustomers: 0,
    topProducts: [],
    categoryShares: [],
  );
}

final analyticsRangeProvider =
    StateProvider<AnalyticsRange>((ref) => AnalyticsRange.month);

/// Derives the analytics summary from live orders and the product catalogue.
final analyticsSummaryProvider = Provider<AnalyticsSummary>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  final orders =
      ref.watch(adminOrdersProvider).valueOrNull ?? const <AdminOrder>[];
  final products = ref.watch(allProductsProvider);

  final categoryByProduct = {
    for (final p in products) p.id: p.categoryName,
  };

  final start = range.startFrom(DateTime.now());
  final inRange = orders
      .map((o) => o.order)
      .where((o) =>
          o.createdAt.isAfter(start) && o.status != OrderStatus.cancelled)
      .toList();

  if (inRange.isEmpty) return AnalyticsSummary.empty;

  var totalRevenue = 0.0;
  var unitsSold = 0;
  final customers = <String>{};
  final unitsByProduct = <String, int>{};
  final revenueByProduct = <String, double>{};
  final revenueByCategory = <String, double>{};

  for (final order in inRange) {
    totalRevenue += order.totalAmount;
    final identity =
        order.userId ?? '${order.customerName}|${order.customerPhone}';
    customers.add(identity);

    for (final item in order.items) {
      unitsSold += item.quantity;
      unitsByProduct.update(item.product.name, (v) => v + item.quantity,
          ifAbsent: () => item.quantity);
      revenueByProduct.update(item.product.name, (v) => v + item.totalPrice,
          ifAbsent: () => item.totalPrice);

      final category = categoryByProduct[item.product.id] ?? 'Uncategorised';
      revenueByCategory.update(category, (v) => v + item.totalPrice,
          ifAbsent: () => item.totalPrice);
    }
  }

  final topProducts = revenueByProduct.keys
      .map((name) => TopProduct(
            name: name,
            unitsSold: unitsByProduct[name] ?? 0,
            revenue: revenueByProduct[name] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  final categoryShares = revenueByCategory.entries
      .map((e) => CategoryShare(
            category: e.key,
            revenue: e.value,
            share: totalRevenue == 0 ? 0 : e.value / totalRevenue,
          ))
      .toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  return AnalyticsSummary(
    totalRevenue: totalRevenue,
    orderCount: inRange.length,
    unitsSold: unitsSold,
    uniqueCustomers: customers.length,
    topProducts: topProducts.take(5).toList(),
    categoryShares: categoryShares,
  );
});
