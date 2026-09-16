import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/product.dart';
import '../../services/firestore_service.dart';

/// Time windows offered by the analytics screen.
enum AnalyticsRange {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisYear('This Year');

  final String label;

  const AnalyticsRange(this.label);

  /// Start of the window, inclusive.
  DateTime startFrom(DateTime now) {
    switch (this) {
      case AnalyticsRange.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsRange.thisWeek:
        // Weeks start on Monday.
        final startOfToday = DateTime(now.year, now.month, now.day);
        return startOfToday.subtract(Duration(days: now.weekday - 1));
      case AnalyticsRange.thisMonth:
        return DateTime(now.year, now.month);
      case AnalyticsRange.thisYear:
        return DateTime(now.year);
    }
  }
}

final analyticsRangeProvider =
    StateProvider<AnalyticsRange>((ref) => AnalyticsRange.thisMonth);

/// One row of the "top selling products" table.
class TopProduct {
  final String name;
  final int unitsSold;
  final double revenue;

  const TopProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });
}

/// One row of the "sales by category" chart.
class CategorySales {
  final String name;
  final double revenue;
  final double share;

  const CategorySales({
    required this.name,
    required this.revenue,
    required this.share,
  });
}

/// Every number the analytics screen displays, derived from real orders.
class AnalyticsSummary {
  final int orderCount;
  final double revenue;
  final double averageOrderValue;
  final int newCustomers;
  final int productsSold;
  final List<TopProduct> topProducts;
  final List<CategorySales> categorySales;

  const AnalyticsSummary({
    required this.orderCount,
    required this.revenue,
    required this.averageOrderValue,
    required this.newCustomers,
    required this.productsSold,
    required this.topProducts,
    required this.categorySales,
  });

  static const empty = AnalyticsSummary(
    orderCount: 0,
    revenue: 0,
    averageOrderValue: 0,
    newCustomers: 0,
    productsSold: 0,
    topProducts: [],
    categorySales: [],
  );
}

/// Computes [AnalyticsSummary] from the live order stream.
final analyticsSummaryProvider = Provider<AsyncValue<AnalyticsSummary>>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  final ordersAsync = ref.watch(_allOrdersProvider);
  final products = ref.watch(_allProductsProvider).valueOrNull ?? const [];

  return ordersAsync.whenData(
    (orders) => _summarise(orders, products, range),
  );
});

final _allOrdersProvider = StreamProvider<List<Order>>((ref) {
  return FirestoreService.instance.ordersStream().map(
        (rows) => rows
            .map((row) => Order.fromMap(row['firestoreId'] as String, row))
            .toList(),
      );
});

final _allProductsProvider = StreamProvider<List<Product>>((ref) {
  return FirestoreService.instance.productsStream();
});

/// Headline numbers for the admin dashboard.
class DashboardStats {
  final int totalProducts;
  final int pendingOrders;
  final double todaySales;
  final int openTickets;

  const DashboardStats({
    required this.totalProducts,
    required this.pendingOrders,
    required this.todaySales,
    required this.openTickets,
  });

  static const empty = DashboardStats(
    totalProducts: 0,
    pendingOrders: 0,
    todaySales: 0,
    openTickets: 0,
  );
}

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final productsAsync = ref.watch(_allProductsProvider);
  final ordersAsync = ref.watch(_allOrdersProvider);
  final ticketsAsync = ref.watch(_openTicketsProvider);

  // Only surface an error once every source agrees the backend is down;
  // otherwise show what did load rather than blanking the whole dashboard.
  final error = [productsAsync, ordersAsync, ticketsAsync]
      .map((a) => a.error)
      .firstWhere((e) => e != null, orElse: () => null);

  if (error != null &&
      productsAsync.hasError &&
      ordersAsync.hasError &&
      ticketsAsync.hasError) {
    return AsyncError(error, StackTrace.current);
  }

  final products = productsAsync.valueOrNull ?? const <Product>[];
  final orders = ordersAsync.valueOrNull ?? const <Order>[];

  final startOfDay = AnalyticsRange.today.startFrom(DateTime.now());
  final todaySales = orders
      .where((o) =>
          !o.createdAt.isBefore(startOfDay) &&
          o.status != OrderStatus.cancelled)
      .fold<double>(0, (sum, o) => sum + o.totalAmount);

  return AsyncData(
    DashboardStats(
      totalProducts: products.length,
      pendingOrders:
          orders.where((o) => o.status == OrderStatus.pending).length,
      todaySales: todaySales,
      openTickets: ticketsAsync.valueOrNull ?? 0,
    ),
  );
});

/// Trimmed order row for the dashboard's "Recent Orders" card.
class RecentOrder {
  final String id;
  final String customerName;
  final double total;
  final OrderStatus status;

  const RecentOrder({
    required this.id,
    required this.customerName,
    required this.total,
    required this.status,
  });
}

/// The five most recent orders, newest first.
final recentOrdersProvider = Provider<AsyncValue<List<RecentOrder>>>((ref) {
  return ref.watch(_allOrdersProvider).whenData(
        (orders) => orders
            .take(5)
            .map((o) => RecentOrder(
                  id: o.id,
                  customerName: o.customerName,
                  total: o.totalAmount,
                  status: o.status,
                ))
            .toList(),
      );
});

final _openTicketsProvider = StreamProvider<int>((ref) {
  return FirestoreService.instance.ticketsStream().map(
        (tickets) =>
            tickets.where((t) => t.status.toLowerCase() != 'resolved').length,
      );
});

AnalyticsSummary _summarise(
  List<Order> orders,
  List<Product> products,
  AnalyticsRange range,
) {
  final cutoff = range.startFrom(DateTime.now());

  // Cancelled orders never represented revenue, so exclude them entirely.
  final relevant = orders.where(
    (o) => !o.createdAt.isBefore(cutoff) && o.status != OrderStatus.cancelled,
  );

  var revenue = 0.0;
  var itemsSold = 0;
  final customers = <String>{};
  final unitsByName = <String, int>{};
  final revenueByName = <String, double>{};

  final categoryByProductId = {
    for (final p in products) p.id: p.categoryName,
  };
  final revenueByCategory = <String, double>{};

  for (final order in relevant) {
    revenue += order.totalAmount;
    if (order.userId != null) customers.add(order.userId!);

    for (final item in order.items) {
      itemsSold += item.quantity;
      final name = item.product.name;
      unitsByName[name] = (unitsByName[name] ?? 0) + item.quantity;
      revenueByName[name] =
          (revenueByName[name] ?? 0) + item.totalPrice;

      final category = categoryByProductId[item.product.id] ?? 'Other';
      revenueByCategory[category] =
          (revenueByCategory[category] ?? 0) + item.totalPrice;
    }
  }

  final orderCount = relevant.length;

  final top = unitsByName.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final topProducts = top
      .take(5)
      .map((e) => TopProduct(
            name: e.key,
            unitsSold: e.value,
            revenue: revenueByName[e.key] ?? 0,
          ))
      .toList();

  final categoryEntries = revenueByCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final totalCategoryRevenue = categoryEntries.fold<double>(
    0,
    (sum, e) => sum + e.value,
  );

  final categorySales = categoryEntries
      .map((e) => CategorySales(
            name: e.key,
            revenue: e.value,
            share: totalCategoryRevenue == 0
                ? 0
                : e.value / totalCategoryRevenue,
          ))
      .toList();

  return AnalyticsSummary(
    orderCount: orderCount,
    revenue: revenue,
    averageOrderValue: orderCount == 0 ? 0 : revenue / orderCount,
    newCustomers: customers.length,
    productsSold: itemsSold,
    topProducts: topProducts,
    categorySales: categorySales,
  );
}