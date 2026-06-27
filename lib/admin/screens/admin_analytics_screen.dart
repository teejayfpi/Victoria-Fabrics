import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range selector
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'this_month',
                    decoration: const InputDecoration(
                      labelText: 'Time Period',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(value: 'this_week', child: Text('This Week')),
                      DropdownMenuItem(value: 'this_month', child: Text('This Month')),
                      DropdownMenuItem(value: 'this_year', child: Text('This Year')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ],
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
                      Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Total Revenue',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '₦2,450,000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('+12.5%', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('vs last month', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
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
                    value: '156',
                    change: '+8%',
                    icon: Icons.shopping_bag,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Avg Order Value',
                    value: '₦15,700',
                    change: '+5%',
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
                    title: 'New Customers',
                    value: '42',
                    change: '+15%',
                    icon: Icons.person_add,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Products Sold',
                    value: '312',
                    change: '+10%',
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
                children: const [
                  _TopProductTile(
                    rank: 1,
                    name: 'Royal Ankara Print',
                    sales: 45,
                    revenue: '₦202,500',
                  ),
                  Divider(height: 1),
                  _TopProductTile(
                    rank: 2,
                    name: 'French Lace Premium',
                    sales: 32,
                    revenue: '₦384,000',
                  ),
                  Divider(height: 1),
                  _TopProductTile(
                    rank: 3,
                    name: 'Pure Silk Fabric',
                    sales: 28,
                    revenue: '₦420,000',
                  ),
                  Divider(height: 1),
                  _TopProductTile(
                    rank: 4,
                    name: 'Classic Dutch Wax Ankara',
                    sales: 24,
                    revenue: '₦132,000',
                  ),
                  Divider(height: 1),
                  _TopProductTile(
                    rank: 5,
                    name: 'Silk Chiffon Premium',
                    sales: 18,
                    revenue: '₦144,000',
                  ),
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
                    _CategorySalesBar(category: 'Ankara', percentage: 0.35, color: Colors.red),
                    const SizedBox(height: 12),
                    _CategorySalesBar(category: 'Lace', percentage: 0.28, color: Colors.purple),
                    const SizedBox(height: 12),
                    _CategorySalesBar(category: 'Silk', percentage: 0.20, color: Colors.blue),
                    const SizedBox(height: 12),
                    _CategorySalesBar(category: 'Cotton', percentage: 0.10, color: Colors.green),
                    const SizedBox(height: 12),
                    _CategorySalesBar(category: 'Others', percentage: 0.07, color: Colors.orange),
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
  final String change;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  change,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
      subtitle: Text('$sales sales'),
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
              '${(percentage * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
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