import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/admin_auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(adminAuthProvider.notifier).logout();
                context.go('/admin/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin?.name ?? 'Admin',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    Text(admin?.email ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.75)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${admin?.name ?? 'Admin'}!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Here's what's happening with Victoria Fabrics today.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            const Text('Overview',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: const [
                _StatCard(
                    title: 'Total Products',
                    value: 'Live',
                    icon: Icons.inventory_2,
                    color: Colors.blue),
                _StatCard(
                    title: 'Pending Orders',
                    value: 'Live',
                    icon: Icons.pending_actions,
                    color: Colors.orange),
                _StatCard(
                    title: 'Today\'s Sales',
                    value: 'Live',
                    icon: Icons.trending_up,
                    color: Colors.green),
                _StatCard(
                    title: 'Open Tickets',
                    value: 'Live',
                    icon: Icons.confirmation_number,
                    color: Colors.purple),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add_circle,
                    title: 'Add Product',
                    color: Colors.blue,
                    onTap: () =>
                        context.push('/admin/products/add'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long,
                    title: 'View Orders',
                    color: Colors.orange,
                    onTap: () => context.push('/admin/orders'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.confirmation_number,
                    title: 'Tickets',
                    color: Colors.purple,
                    onTap: () => context.push('/admin/tickets'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    color: Colors.green,
                    onTap: () =>
                        context.push('/admin/analytics'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent orders placeholder
            const Text('Recent Orders',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor)),
            const SizedBox(height: 12),
            _RecentOrdersList(),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.notifications,
                    color: Colors.white, size: 20),
              ),
              title: const Text('New Order received'),
              subtitle: const Text('2 minutes ago'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.confirmation_number,
                    color: Colors.white, size: 20),
              ),
              title: const Text('New support ticket'),
              subtitle: const Text('15 minutes ago'),
            ),
            const SizedBox(height: 16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: Icon(icon, color: color, size: 22),
                ),
                const Icon(Icons.circle,
                    size: 8, color: Colors.green),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(title,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _OrderTile(
              orderId: 'ORD-001',
              customer: 'Adebayo Johnson',
              amount: '₦125,000',
              status: 'Pending',
              statusColor: Colors.orange),
          const Divider(height: 1),
          _OrderTile(
              orderId: 'ORD-002',
              customer: 'Chioma Adekunle',
              amount: '₦245,000',
              status: 'Confirmed',
              statusColor: Colors.blue),
          const Divider(height: 1),
          _OrderTile(
              orderId: 'ORD-003',
              customer: 'Emmanuel Obi',
              amount: '₦45,000',
              status: 'Delivered',
              statusColor: Colors.green),
          const Divider(height: 1),
          ListTile(
            onTap: () => context.push('/admin/orders'),
            title: const Text('View all orders →',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String orderId;
  final String customer;
  final String amount;
  final String status;
  final Color statusColor;

  const _OrderTile({
    required this.orderId,
    required this.customer,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: const Icon(Icons.receipt,
            color: AppTheme.primaryColor, size: 18),
      ),
      title: Text(orderId,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(customer),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      onTap: () => context.push('/admin/orders'),
    );
  }
}
