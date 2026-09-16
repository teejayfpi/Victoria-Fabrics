class Category {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String iconName;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconName': iconName,
    };
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'checkroom',
    );
  }
}