import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/domain/entities/category.dart';

void main() {
  const category = Category(
    id: 'cat_1',
    name: 'Ankara',
    description: 'Vibrant African print fabrics',
    imageUrl: 'https://example.com/ankara.jpg',
    iconName: 'checkroom',
  );

  group('Category serialisation', () {
    test('survives toMap/fromMap round-trip', () {
      final restored = Category.fromMap('cat_1', category.toMap());

      expect(restored.id, 'cat_1');
      expect(restored.name, category.name);
      expect(restored.description, category.description);
      expect(restored.imageUrl, category.imageUrl);
      expect(restored.iconName, category.iconName);
    });

    test('fromMap tolerates missing fields', () {
      final restored = Category.fromMap('cat_9', const {});

      expect(restored.id, 'cat_9');
      expect(restored.name, '');
      expect(restored.iconName, 'checkroom');
    });
  });

  group('Category.copyWith', () {
    test('updates only the supplied fields', () {
      final updated = category.copyWith(name: 'Lace');

      expect(updated.name, 'Lace');
      expect(updated.id, category.id);
      expect(updated.description, category.description);
      expect(updated.imageUrl, category.imageUrl);
    });
  });
}
