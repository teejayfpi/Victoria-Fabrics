import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product, int quantity, String unit) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id && item.selectedUnit == unit,
    );

    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [
        ...state,
        CartItem(product: product, quantity: quantity, selectedUnit: unit),
      ];
    }
    print('[Fabric Haven] Added to cart: ${product.name} x$quantity $unit');
  }

  void removeFromCart(String productId, String unit) {
    state = state.where(
      (item) => !(item.product.id == productId && item.selectedUnit == unit),
    ).toList();
  }

  void updateQuantity(String productId, String unit, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId, unit);
      return;
    }

    final index = state.indexWhere(
      (item) => item.product.id == productId && item.selectedUnit == unit,
    );

    if (index >= 0) {
      final updatedItem = state[index].copyWith(quantity: quantity);
      state = [
        ...state.sublist(0, index),
        updatedItem,
        ...state.sublist(index + 1),
      ];
    }
  }

  void clearCart() {
    state = [];
    print('[Fabric Haven] Cart cleared');
  }

  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount => state.fold(0, (sum, item) => sum + item.totalPrice);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartTotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(0, (sum, item) => sum + item.quantity);
});