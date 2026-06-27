import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

class MockDataSource {
  static final List<Category> categories = [
    const Category(
      id: 'cat_1',
      name: 'Ankara',
      description: 'Vibrant African print fabrics',
      imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
      iconName: 'checkroom',
    ),
    const Category(
      id: 'cat_2',
      name: 'Lace',
      description: 'Elegant lace fabrics for special occasions',
      imageUrl: 'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=400',
      iconName: 'texture',
    ),
    const Category(
      id: 'cat_3',
      name: 'Cotton',
      description: 'Soft and breathable cotton fabrics',
      imageUrl: 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=400',
      iconName: 'grass',
    ),
    const Category(
      id: 'cat_4',
      name: 'Silk',
      description: 'Luxurious silk fabrics',
      imageUrl: 'https://images.unsplash.com/photo-1558171814-11c5fc90587b?w=400',
      iconName: 'auto_awesome',
    ),
    const Category(
      id: 'cat_5',
      name: 'Voile',
      description: 'Light and airy voile fabrics',
      imageUrl: 'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?w=400',
      iconName: 'air',
    ),
    const Category(
      id: 'cat_6',
      name: 'Chiffon',
      description: 'Delicate chiffon for elegant wear',
      imageUrl: 'https://images.unsplash.com/photo-1550614000-4895a10e1bfd?w=400',
      iconName: 'spa',
    ),
  ];

  static final List<Product> products = [
    // Ankara products
    const Product(
      id: 'prod_1',
      name: 'Royal Ankara Print',
      description: 'Beautiful vibrant ankara fabric with traditional Nigerian patterns. Perfect for dresses, blouses, and casual wear. This fabric is known for its vivid colors and bold designs that celebrate African heritage.',
      categoryId: 'cat_1',
      categoryName: 'Ankara',
      imageUrls: [
        'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600',
        'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=600',
      ],
      pricePerYard: 4500,
      pricePerMeter: 4900,
      pricePerPiece: 18000,
      inStock: true,
      colors: ['Red & Gold', 'Blue & White', 'Green & Yellow'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    const Product(
      id: 'prod_2',
      name: 'Classic Dutch Wax Ankara',
      description: 'Premium quality Dutch wax ankara fabric with authentic African prints. Known for its durability and rich color retention. Ideal for traditional and contemporary fashion.',
      categoryId: 'cat_1',
      categoryName: 'Ankara',
      imageUrls: [
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
      ],
      pricePerYard: 5500,
      pricePerMeter: 6000,
      pricePerPiece: 22000,
      inStock: true,
      colors: ['Purple & Gold', 'Orange & Black'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    const Product(
      id: 'prod_3',
      name: 'Modern Ankara Stripes',
      description: 'Contemporary ankara fabric with modern stripe patterns. Great for creating stylish outfits that blend tradition with modern fashion trends.',
      categoryId: 'cat_1',
      categoryName: 'Ankara',
      imageUrls: [
        'https://images.unsplash.com/photo-1558171814-11c5fc90587b?w=600',
      ],
      pricePerYard: 4000,
      pricePerMeter: 4350,
      pricePerPiece: 16000,
      inStock: true,
      colors: ['Multi-color', 'Pink & Teal'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    // Lace products
    const Product(
      id: 'prod_4',
      name: 'French Lace Premium',
      description: 'Exquisite French lace with intricate floral patterns. Perfect for wedding dresses, traditional ceremonies, and special occasions. This high-quality lace adds elegance to any outfit.',
      categoryId: 'cat_2',
      categoryName: 'Lace',
      imageUrls: [
        'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=600',
      ],
      pricePerYard: 12000,
      pricePerMeter: 13100,
      pricePerPiece: 48000,
      inStock: true,
      colors: ['White', 'Ivory', 'Champagne'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    const Product(
      id: 'prod_5',
      name: 'Ankara Lace Combo',
      description: 'Beautiful combination of ankara and lace fabric. Perfect for owambe and traditional events. This unique fabric features ankara prints with lace accents.',
      categoryId: 'cat_2',
      categoryName: 'Lace',
      imageUrls: [
        'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600',
      ],
      pricePerYard: 8500,
      pricePerMeter: 9300,
      pricePerPiece: 34000,
      inStock: true,
      colors: ['Blue', 'Red', 'Green'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    const Product(
      id: 'prod_6',
      name: 'Cord Lace Classic',
      description: 'Traditional cord lace with timeless appeal. Ideal for church outfits, weddings, and formal occasions. Features raised cord patterns on delicate lace base.',
      categoryId: 'cat_2',
      categoryName: 'Lace',
      imageUrls: [
        'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?w=600',
      ],
      pricePerYard: 7500,
      pricePerMeter: 8200,
      pricePerPiece: 30000,
      inStock: true,
      colors: ['White', 'Black', 'Wine'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    // Cotton products
    const Product(
      id: 'prod_7',
      name: 'Premium Nigerian Cotton',
      description: 'Soft and comfortable Nigerian cotton fabric. Perfect for everyday wear, casual outfits, and children clothing. Breathable and gentle on the skin.',
      categoryId: 'cat_3',
      categoryName: 'Cotton',
      imageUrls: [
        'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=600',
      ],
      pricePerYard: 2500,
      pricePerMeter: 2750,
      pricePerPiece: 10000,
      inStock: true,
      colors: ['White', 'Navy', 'Brown'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    const Product(
      id: 'prod_8',
      name: 'Printed Cotton Fabric',
      description: 'Colorful printed cotton with various patterns. Great for creating vibrant summer outfits, dresses, and casual wear. Easy to wash and maintain.',
      categoryId: 'cat_3',
      categoryName: 'Cotton',
      imageUrls: [
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
      ],
      pricePerYard: 3000,
      pricePerMeter: 3300,
      pricePerPiece: 12000,
      inStock: true,
      colors: ['Floral', 'Geometric', 'Abstract'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    // Silk products
    const Product(
      id: 'prod_9',
      name: 'Pure Silk Fabric',
      description: 'Luxurious pure silk with beautiful sheen. Perfect for formal wear, blouses, and special occasion outfits. This premium silk drapes beautifully and feels amazing against the skin.',
      categoryId: 'cat_4',
      categoryName: 'Silk',
      imageUrls: [
        'https://images.unsplash.com/photo-1558171814-11c5fc90587b?w=600',
      ],
      pricePerYard: 15000,
      pricePerMeter: 16400,
      pricePerPiece: 60000,
      inStock: true,
      colors: ['Burgundy', 'Navy', 'Emerald'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    const Product(
      id: 'prod_10',
      name: 'Satin Silk Blend',
      description: 'Elegant satin silk blend with smooth finish. Ideal for wedding dresses, traditional ceremonies, and upscale events. Combines the beauty of silk with practical durability.',
      categoryId: 'cat_4',
      categoryName: 'Silk',
      imageUrls: [
        'https://images.unsplash.com/photo-1558171814-11c5fc90587b?w=600',
      ],
      pricePerYard: 9500,
      pricePerMeter: 10400,
      pricePerPiece: 38000,
      inStock: true,
      colors: ['Gold', 'Silver', 'Rose'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    // Voile products
    const Product(
      id: 'prod_11',
      name: 'Light Cotton Voile',
      description: 'Soft and lightweight cotton voile. Perfect for summer blouses, dresses, and scarves. This breathable fabric keeps you cool in hot weather.',
      categoryId: 'cat_5',
      categoryName: 'Voile',
      imageUrls: [
        'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?w=600',
      ],
      pricePerYard: 3500,
      pricePerMeter: 3800,
      pricePerPiece: 14000,
      inStock: true,
      colors: ['White', 'Pastel Pink', 'Sky Blue'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
    // Chiffon products
    const Product(
      id: 'prod_12',
      name: 'Silk Chiffon Premium',
      description: 'Delicate silk chiffon with ethereal drape. Perfect for evening gowns, scarves, and elegant blouses. This lightweight fabric flows beautifully with movement.',
      categoryId: 'cat_6',
      categoryName: 'Chiffon',
      imageUrls: [
        'https://images.unsplash.com/photo-1550614000-4895a10e1bfd?w=600',
      ],
      pricePerYard: 8000,
      pricePerMeter: 8750,
      pricePerPiece: 32000,
      inStock: true,
      colors: ['Blush', 'Lavender', 'Coral'],
      availableUnits: ['Yard', 'Meter', 'Piece'],
    ),
  ];

  static List<Product> getProductsByCategory(String categoryId) {
    return products.where((p) => p.categoryId == categoryId).toList();
  }

  static Product? getProductById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Product> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return products.where((p) =>
      p.name.toLowerCase().contains(lowercaseQuery) ||
      p.description.toLowerCase().contains(lowercaseQuery) ||
      p.categoryName.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  static List<Product> getFeaturedProducts() {
    return products.where((p) => p.inStock).take(6).toList();
  }
}