import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final List<String> imageUrls;
  final double pricePerYard;
  final double pricePerMeter;
  final double pricePerPiece;
  final bool inStock;
  final List<String> colors;
  final List<String> availableUnits;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrls,
    required this.pricePerYard,
    required this.pricePerMeter,
    required this.pricePerPiece,
    required this.inStock,
    required this.colors,
    required this.availableUnits,
  });

  double getPrice(String unit) {
    switch (unit.toLowerCase()) {
      case 'yard':
        return pricePerYard;
      case 'meter':
        return pricePerMeter;
      case 'piece':
        return pricePerPiece;
      default:
        return pricePerYard;
    }
  }

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrls': imageUrls,
      'pricePerYard': pricePerYard,
      'pricePerMeter': pricePerMeter,
      'pricePerPiece': pricePerPiece,
      'inStock': inStock,
      'colors': colors,
      'availableUnits': availableUnits,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
      pricePerYard: (map['pricePerYard'] as num? ?? 0).toDouble(),
      pricePerMeter: (map['pricePerMeter'] as num? ?? 0).toDouble(),
      pricePerPiece: (map['pricePerPiece'] as num? ?? 0).toDouble(),
      inStock: map['inStock'] as bool? ?? true,
      colors: List<String>.from(map['colors'] as List? ?? []),
      availableUnits: List<String>.from(
          map['availableUnits'] as List? ?? ['Yard', 'Meter', 'Piece']),
    );
  }

  /// Lightweight placeholder used when reconstructing order items from Firestore.
  /// Only id, name, and one imageUrl are populated — enough for order history display.
  factory Product.placeholder({
    required String id,
    required String name,
    required String imageUrl,
  }) {
    return Product(
      id: id,
      name: name,
      description: '',
      categoryId: '',
      categoryName: '',
      imageUrls: imageUrl.isNotEmpty ? [imageUrl] : [],
      pricePerYard: 0,
      pricePerMeter: 0,
      pricePerPiece: 0,
      inStock: true,
      colors: const [],
      availableUnits: const ['Yard', 'Meter', 'Piece'],
    );
  }

  Product copyWith({
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    List<String>? imageUrls,
    double? pricePerYard,
    double? pricePerMeter,
    double? pricePerPiece,
    bool? inStock,
    List<String>? colors,
    List<String>? availableUnits,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrls: imageUrls ?? this.imageUrls,
      pricePerYard: pricePerYard ?? this.pricePerYard,
      pricePerMeter: pricePerMeter ?? this.pricePerMeter,
      pricePerPiece: pricePerPiece ?? this.pricePerPiece,
      inStock: inStock ?? this.inStock,
      colors: colors ?? this.colors,
      availableUnits: availableUnits ?? this.availableUnits,
    );
  }
}
