import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/product.dart';
import '../providers/cart_provider.dart';

/// Adds one unit of [product] to the cart from a catalogue grid.
///
/// Grid cards have no unit picker, so the product's first available unit is
/// used. The cart line ceiling is enforced here (rather than silently dropping
/// the item) so the user is told why nothing happened.
void quickAddToCart(BuildContext context, WidgetRef ref, Product product) {
  final cart = ref.read(cartProvider);
  final unit =
      product.availableUnits.isNotEmpty ? product.availableUnits.first : 'Yard';

  final alreadyInCart = cart.any(
    (item) => item.product.id == product.id && item.selectedUnit == unit,
  );
  if (!alreadyInCart && cart.length >= CartNotifier.maxLines) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your cart is limited to ${CartNotifier.maxLines} items. '
          'Please remove one before adding another.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  ref.read(cartProvider.notifier).addToCart(product, 1, unit);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${product.name} added to cart'),
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: 'View Cart',
        onPressed: () => context.push('/cart'),
      ),
    ),
  );
}
