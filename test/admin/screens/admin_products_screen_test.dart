import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fabric_haven/admin/providers/admin_auth_provider.dart';
import 'package:fabric_haven/admin/screens/admin_products_screen.dart';
import 'package:fabric_haven/core/providers/repository_providers.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';
import 'package:fabric_haven/data/repositories/product_repository.dart';
import 'package:fabric_haven/domain/entities/product.dart';
import 'package:fabric_haven/presentation/providers/category_provider.dart';
import 'package:fabric_haven/presentation/providers/product_provider.dart';
import 'package:fabric_haven/services/firestore_service.dart';

const _product = Product(
  id: 'p1',
  name: 'Royal Ankara',
  description: 'Wax print',
  categoryId: 'c1',
  categoryName: 'Ankara',
  imageUrls: [],
  pricePerYard: 5000,
  pricePerMeter: 5500,
  pricePerPiece: 12000,
  inStock: true,
  colors: [],
  availableUnits: ['Yard', 'Meter', 'Piece'],
);

const _admin = AdminUser(
  id: 'a1',
  email: 'owner@example.com',
  name: 'Ada Obi',
  role: AdminRole.admin,
);

/// A Firestore service whose only live-looking method is the product delete, so
/// the admin delete flow can be exercised without a project. This covers the
/// reported "I want to be able to delete any one of my products".
class _DeleteRecordingFirestore extends FirestoreService {
  _DeleteRecordingFirestore() : super.forTest();

  final deleted = <String>[];

  @override
  Future<void> deleteProduct(String id) async {
    deleted.add(id);
  }
}

void main() {
  testWidgets('admin can delete a product from the products list',
      (tester) async {
    final firestore = _DeleteRecordingFirestore();

    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAdminProvider.overrideWithValue(_admin),
          allProductsStreamProvider
              .overrideWith((ref) => Stream.value(const [_product])),
          categoriesStreamProvider.overrideWith((ref) => Stream.value(const [])),
          firestoreServiceProvider.overrideWithValue(firestore),
          productRepositoryProvider.overrideWith(
            (ref) => ProductRepository(firestore),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminProductsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Royal Ankara'), findsOneWidget);

    // Delete icon on the card opens a confirmation dialog.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete Product'), findsOneWidget);

    // Confirming runs the (recorded) delete and reports success.
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(firestore.deleted, ['p1']);
    expect(find.text('Royal Ankara has been removed'), findsOneWidget);
  });
}
