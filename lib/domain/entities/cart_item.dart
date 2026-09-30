import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final String selectedUnit;

  /// Price per unit captured at the time the item was added. When null the
  /// price is resolved from the product catalogue (live cart behaviour).
  /// Reconstructed order items carry the snapshot so historical totals stay
  /// correct even after a product's price changes.
  final double? unitPriceOverride;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.selectedUnit,
    this.unitPriceOverride,
  });

  double get unitPrice => unitPriceOverride ?? product.getPrice(selectedUnit);
  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? selectedUnit,
    double? unitPriceOverride,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      unitPriceOverride: unitPriceOverride ?? this.unitPriceOverride,
    );
  }
}