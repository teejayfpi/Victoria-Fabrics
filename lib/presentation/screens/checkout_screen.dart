import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../../domain/entities/order.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/payment_constants.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DeliveryType _deliveryType = DeliveryType.delivery;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Pre-fill name from Google account (runs once when widget is ready)
  void _prefillFromAuth() {
    if (_prefilled) return;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      if (user.displayName != null && _nameController.text.isEmpty) {
        _nameController.text = user.displayName!;
      }
    }
    _prefilled = true;
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    final cartItems = ref.read(cartProvider);
    final totalAmount = ref.read(cartTotalProvider);

    ref.read(orderProvider.notifier).createOrder(
          items: cartItems,
          totalAmount: totalAmount,
          deliveryType: _deliveryType,
          deliveryAddress: _deliveryType == DeliveryType.delivery
              ? _addressController.text
              : null,
          pickupLocation: _deliveryType == DeliveryType.pickup
              ? 'Victoria Fabrics Store, Lagos'
              : null,
          customerName: _nameController.text,
          customerPhone: _phoneController.text,
        );

    ref.read(cartProvider.notifier).clearCart();
    context.go('/order-confirmation');
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fill once auth is available
    _prefillFromAuth();

    final totalAmount = ref.watch(cartTotalProvider);
    final grandTotal = _deliveryType == DeliveryType.delivery
        ? totalAmount + 2500
        : totalAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Delivery method ──────────────────────────────────────
              const _SectionHeader('Delivery Method'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DeliveryTypeCard(
                      icon: Icons.local_shipping,
                      title: 'Delivery',
                      subtitle: 'To your address',
                      isSelected: _deliveryType == DeliveryType.delivery,
                      onTap: () =>
                          setState(() => _deliveryType = DeliveryType.delivery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DeliveryTypeCard(
                      icon: Icons.store,
                      title: 'Pickup',
                      subtitle: 'From our store',
                      isSelected: _deliveryType == DeliveryType.pickup,
                      onTap: () =>
                          setState(() => _deliveryType = DeliveryType.pickup),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Customer information ──────────────────────────────────
              const _SectionHeader('Customer Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter your phone number'
                    : null,
              ),
              const SizedBox(height: 24),

              // ── Delivery address / Pickup ─────────────────────────────
              if (_deliveryType == DeliveryType.delivery) ...[
                const _SectionHeader('Delivery Address'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      (_deliveryType == DeliveryType.delivery &&
                              (v == null || v.isEmpty))
                          ? 'Please enter your delivery address'
                          : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery fee: ₦2,500',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'Victoria Fabrics Store\n15 Admiralty Way, Lekki Phase 1, Lagos',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Payment method ────────────────────────────────────────
              const _SectionHeader('Payment Method'),
              const SizedBox(height: 12),
              _BankTransferCard(totalAmount: grandTotal),
              const SizedBox(height: 24),

              // ── Order summary ─────────────────────────────────────────
              const _SectionHeader('Order Summary'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Subtotal',
                      value: '₦${totalAmount.toStringAsFixed(0)}',
                    ),
                    _SummaryRow(
                      label: 'Delivery Fee',
                      value: _deliveryType == DeliveryType.delivery
                          ? '₦2,500'
                          : '₦0',
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: 'Total',
                      value: '₦${grandTotal.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Place order button ────────────────────────────────────
              ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bank Transfer Card ─────────────────────────────────────────────────────

class _BankTransferCard extends StatelessWidget {
  final double totalAmount;
  const _BankTransferCard({required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBD6F7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance,
                    color: Color(0xFF1565C0), size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'Bank Transfer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            PaymentConstants.paymentInstructions,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),
          _BankDetailRow(label: 'Bank', value: PaymentConstants.bankName),
          const SizedBox(height: 6),
          _BankDetailRow(
            label: 'Account Name',
            value: PaymentConstants.accountName,
          ),
          const SizedBox(height: 6),
          _BankDetailRow(
            label: 'Account Number',
            value: PaymentConstants.accountNumber,
            copyable: true,
          ),
          const SizedBox(height: 6),
          _BankDetailRow(
            label: 'Amount',
            value: '₦${totalAmount.toStringAsFixed(0)}',
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final bool highlight;

  const _BankDetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: highlight
                    ? AppTheme.secondaryColor
                    : const Color(0xFF1A237E),
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account number copied!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(Icons.copy, size: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Shared section header ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textColor,
      ),
    );
  }
}

// ── Delivery type card ─────────────────────────────────────────────────────

class _DeliveryTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: isSelected ? AppTheme.primaryColor : Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : Colors.black,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary row ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.textColor : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 20 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.secondaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
