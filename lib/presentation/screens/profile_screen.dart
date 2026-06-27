import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Guest User',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to access your account',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Demo mode - show login dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Demo Mode'),
                          content: const Text(
                            'This is a demo app. In production, this would open a login screen.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu items
            _MenuItem(
              icon: Icons.receipt_long,
              title: 'My Orders',
              subtitle: 'View your order history',
              onTap: () => context.push('/orders'),
            ),
            _MenuItem(
              icon: Icons.location_on,
              title: 'Delivery Addresses',
              subtitle: 'Manage your addresses',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo mode - addresses not available')),
                );
              },
            ),
            _MenuItem(
              icon: Icons.favorite,
              title: 'Wishlist',
              subtitle: 'Your saved items',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo mode - wishlist not available')),
                );
              },
            ),
            _MenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo mode - notifications not available')),
                );
              },
            ),
            _MenuItem(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help with your orders',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo mode - help not available')),
                );
              },
            ),
            _MenuItem(
              icon: Icons.info,
              title: 'About',
              subtitle: 'App version 1.0.0',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Fabric Haven',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 Fabric Haven\nYour Neighbourhood Fabric Store',
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Browse and shop for quality fabrics including Ankara, Lace, Cotton, Silk, and more.',
                    ),
                  ],
                );
              },
            ),
            _MenuItem(
              icon: Icons.admin_panel_settings,
              title: 'Admin Portal',
              subtitle: 'Manage your store',
              onTap: () {
                Navigator.pushNamed(context, '/admin');
              },
            ),
            const SizedBox(height: 24),

            // Logout button (demo)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo mode - logout not available')),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}