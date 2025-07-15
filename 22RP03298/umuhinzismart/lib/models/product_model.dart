class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String dealer;
  final String category;
  final int? stock;
  final int? minStock;
  final DateTime? createdAt;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.dealer,
    required this.category,
    this.stock,
    this.minStock,
    this.createdAt,
    this.isActive = true,
  });

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    // Safe parsing functions
    double safeDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int? safeInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    DateTime? safeDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Product(
      id: documentId,
      name: data['name']?.toString().trim() ?? 'Unknown Product',
      description: data['description']?.toString().trim() ?? '',
      price: safeDouble(data['price']),
      imageUrl: data['imageUrl']?.toString().trim() ?? '',
      dealer: data['dealer']?.toString().trim() ?? 'Unknown Dealer',
      category: data['category']?.toString().trim() ?? 'General',
      stock: safeInt(data['stock']),
      minStock: safeInt(data['minStock']),
      createdAt: safeDateTime(data['createdAt']),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.isNotEmpty ? name : 'No name',
      'description': description.isNotEmpty ? description : 'No description',
      'price': price,
      'imageUrl': imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/300x200?text=No+Image',
      'dealer': dealer.isNotEmpty ? dealer : 'Unknown',
      'category': category.isNotEmpty ? category : 'General',
      'stock': stock ?? 0,
      'minStock': minStock ?? 5,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Validation methods
  bool get isValid => 
    name.isNotEmpty && 
    price > 0 && 
    dealer.isNotEmpty;

  bool get isInStock => 
    stock == null || stock! > 0;

  bool get needsRestock => 
    minStock != null && 
    stock != null && 
    stock! <= minStock!;

  // Copy with methods for updates
  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? dealer,
    String? category,
    int? stock,
    int? minStock,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      dealer: dealer ?? this.dealer,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, dealer: $dealer)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 