import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/admin_analytics_providers.dart';
import '../providers/admin_data_providers.dart';

/// Palette used to colour category bars, cycled when there are more
/// categories than colours.
const _categoryPalette = <Color>[
  Colors.red,
  Colors.purple,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.teal,
  Colors.indigo,
  Colors.brown,
];

String _formatNaira(double amount) {
  final whole = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return '₦$buffer';
}

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analyticsRangeProvider);
    final asyncOrders = ref.watch(adminOrdersProvider);
    final summary = ref.watch(analyticsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: asyncOrders.isLoading && summary.orderCount == 0
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range selector
                  DropdownButtonFormField<AnalyticsRange>(
                    value: range,
                    decoration: const InputDecoration(
                      labelText: 'Time Period',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: [
                      for (final value in AnalyticsRange.values)
                        DropdownMenuItem(
                            value: value, child: Text(value.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(analyticsRangeProvider.notifier).state = value;
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Revenue card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[700]!, Colors.green[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text('Total Revenue',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatNaira(summary.totalRevenue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.orderCount} orders · ${range.label}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Orders',
                          value: '${summary.orderCount}',
                          icon: Icons.shopping_bag,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Avg Order Value',
                          value: _formatNaira(summary.averageOrderValue),
                          icon: Icons.receipt,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Customers',
                          value: '${summary.uniqueCustomers}',
                          icon: Icons.person_add,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Products Sold',
                          value: '${summary.unitsSold}',
                          icon: Icons.inventory,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Top selling products
                  const Text(
                    'Top Selling Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        if (summary.topProducts.isEmpty)
                          const ListTile(
                            title: Text('No sales in this period',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey)),
                          )
                        else
                          for (var i = 0;
                              i < summary.topProducts.length;
                              i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _TopProductTile(
                                rank: i + 1, product: summary.topProducts[i]),
                          ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sales by category
                  const Text(
                    'Sales by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (summary.categoryShares.isEmpty)
                            const Text('No category sales yet',
                                style: TextStyle(color: Colors.grey))
                          else
                            for (var i = 0;
                                i < summary.categoryShares.length;
                                i++) ...[
                              if (i > 0) const SizedBox(height: 12),
                              _CategorySalesBar(
                                share: summary.categoryShares[i],
                                color: _categoryPalette[
                                    i % _categoryPalette.length],
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final int rank;
  final TopProduct product;

  const _TopProductTile({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rank <= 3 ? AppTheme.primaryColor : Colors.grey[300],
        child: Text(
          '$rank',
          style: TextStyle(
            color: rank <= 3 ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title:
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${product.unitsSold} sold'),
      trailing: Text(
        _formatNaira(product.revenue),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}

class _CategorySalesBar extends StatelessWidget {
  final CategoryShare share;
  final Color color;

  const _CategorySalesBar({required this.share, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(share.category,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${(share.share * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: share.share,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
