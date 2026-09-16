import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state.dart';
import '../providers/analytics_provider.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analyticsRangeProvider);
    final summaryAsync = ref.watch(analyticsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: summaryAsync.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          title: 'Could not load analytics',
          error: error,
          onRetry: () => ref.invalidate(analyticsSummaryProvider),
        ),
        data: (summary) {
          if (summary.orderCount == 0) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No sales in this period',
              message:
                  'Analytics appear here once orders come in for the selected '
                  'date range.',
            );
          }

          final currency = NumberFormat.currency(
            symbol: '₦',
            decimalDigits: 0,
          );

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(analyticsSummaryProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<AnalyticsRange>(
                    value: range,
                    decoration: const InputDecoration(
                      labelText: 'Time Period',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: AnalyticsRange.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(analyticsRangeProvider.notifier).state = value;
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  _RevenueCard(
                    revenue: summary.revenue,
                    orderCount: summary.orderCount,
                    rangeLabel: range.label,
                  ),
                  const SizedBox(height: 24),

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
                          value: currency.format(summary.averageOrderValue),
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
                          value: '${summary.newCustomers}',
                          icon: Icons.person_add,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Products Sold',
                          value: '${summary.productsSold}',
                          icon: Icons.inventory,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (summary.topProducts.isNotEmpty) ...[
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
                          for (var i = 0; i < summary.topProducts.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _TopProductTile(
                              rank: i + 1,
                              name: summary.topProducts[i].name,
                              sales: summary.topProducts[i].unitsSold,
                              revenue:
                                  currency.format(summary.topProducts[i].revenue),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (summary.categorySales.isNotEmpty) ...[
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
                            for (var i = 0;
                                i < summary.categorySales.length;
                                i++) ...[
                              if (i > 0) const SizedBox(height: 12),
                              _CategorySalesBar(
                                category: summary.categorySales[i].name,
                                percentage: summary.categorySales[i].share,
                                color: _barColor(i),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static const _palette = [
    Colors.red,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.teal,
  ];

  Color _barColor(int index) => _palette[index % _palette.length];
}

class _RevenueCard extends StatelessWidget {
  final double revenue;
  final int orderCount;
  final String rangeLabel;

  const _RevenueCard({
    required this.revenue,
    required this.orderCount,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Container(
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
              Text(
                'Total Revenue',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(revenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From $orderCount order${orderCount == 1 ? '' : 's'} • $rangeLabel',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
  final String name;
  final int sales;
  final String revenue;

  const _TopProductTile({
    required this.rank,
    required this.name,
    required this.sales,
    required this.revenue,
  });

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
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$sales sold'),
      trailing: Text(
        revenue,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}

class _CategorySalesBar extends StatelessWidget {
  final String category;
  final double percentage;
  final Color color;

  const _CategorySalesBar({
    required this.category,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}