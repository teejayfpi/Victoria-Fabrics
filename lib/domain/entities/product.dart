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
}