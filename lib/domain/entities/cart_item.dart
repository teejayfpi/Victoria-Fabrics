import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final String selectedUnit;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.selectedUnit,
  });

  double get unitPrice => product.getPrice(selectedUnit);
  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? selectedUnit,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedUnit: selectedUnit ?? this.selectedUnit,
    );
  }
}