class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final String category;
  final String condition;
  final String sellerId;
  final String sellerName;
  final List<String> images;
  final DateTime createdAt;
  final bool isAvailable;
  final String? size;
  final String? brand;
  final String? color;
  final int? viewCount;
  final int? likeCount;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.category,
    required this.condition,
    required this.sellerId,
    required this.sellerName,
    required this.images,
    required this.createdAt,
    this.isAvailable = true,
    this.size,
    this.brand,
    this.color,
    this.viewCount = 0,
    this.likeCount = 0,
  });

  // Calculate discount percentage
  double get discountPercentage {
    return ((originalPrice - price) / originalPrice * 100).roundToDouble();
  }

  // Check if product has discount
  bool get hasDiscount => originalPrice > price;

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'condition': condition,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'isAvailable': isAvailable,
      'size': size,
      'brand': brand,
      'color': color,
      'viewCount': viewCount,
      'likeCount': likeCount,
    };
  }

  // Create from Map (from Firebase)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      condition: map['condition'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isAvailable: map['isAvailable'] ?? true,
      size: map['size'],
      brand: map['brand'],
      color: map['color'],
      viewCount: map['viewCount'] ?? 0,
      likeCount: map['likeCount'] ?? 0,
    );
  }

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? condition,
    String? sellerId,
    String? sellerName,
    List<String>? images,
    DateTime? createdAt,
    bool? isAvailable,
    String? size,
    String? brand,
    String? color,
    int? viewCount,
    int? likeCount,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
    );
  }
} 