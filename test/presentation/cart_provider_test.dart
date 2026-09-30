import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/domain/entities/product.dart';
import 'package:fabric_haven/presentation/providers/cart_provider.dart';

Product _product(String id) => Product(
      id: id,
      name: 'Fabric $id',
      description: '',
      categoryId: 'ankara',
      categoryName: 'Ankara',
      imageUrls: const [],
      pricePerYard: 5000,
      pricePerMeter: 5500,
      pricePerPiece: 12000,
      inStock: true,
      colors: const [],
      availableUnits: const ['Yard', 'Meter', 'Piece'],
    );

void main() {
  group('CartNotifier line ceiling', () {
    test('accepts up to maxLines distinct lines', () {
      final cart = CartNotifier();
      for (var i = 0; i < CartNotifier.maxLines; i++) {
        cart.addToCart(_product('p$i'), 1, 'Yard');
      }
      expect(cart.state.length, CartNotifier.maxLines);
    });

    test('rejects a new line beyond maxLines', () {
      final cart = CartNotifier();
      for (var i = 0; i < CartNotifier.maxLines; i++) {
        cart.addToCart(_product('p$i'), 1, 'Yard');
      }
      cart.addToCart(_product('overflow'), 1, 'Yard');

      expect(cart.state.length, CartNotifier.maxLines);
      expect(
        cart.state.any((i) => i.product.id == 'overflow'),
        isFalse,
      );
    });

    test('still increments an existing line at the ceiling', () {
      final cart = CartNotifier();
      for (var i = 0; i < CartNotifier.maxLines; i++) {
        cart.addToCart(_product('p$i'), 1, 'Yard');
      }
      cart.addToCart(_product('p0'), 2, 'Yard');

      expect(cart.state.length, CartNotifier.maxLines);
      expect(
        cart.state.firstWhere((i) => i.product.id == 'p0').quantity,
        3,
      );
    });
  });
}
