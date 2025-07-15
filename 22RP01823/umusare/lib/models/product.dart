class Product {
  final String id;
  final String name;
  final String image;
  final String freshness;
  final double price;
  final String priceUnit;
  final String description;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.freshness,
    required this.price,
    required this.priceUnit,
    required this.description,
    required this.category,
  });

  String get formattedPrice => '${price.toStringAsFixed(0)} RWF/$priceUnit';

  Product copyWith({
    String? id,
    String? name,
    String? image,
    String? freshness,
    double? price,
    String? priceUnit,
    String? description,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      freshness: freshness ?? this.freshness,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'freshness': freshness,
      'price': price,
      'priceUnit': priceUnit,
      'description': description,
      'category': category,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      freshness: json['freshness'],
      price: json['price'].toDouble(),
      priceUnit: json['priceUnit'],
      description: json['description'],
      category: json['category'],
    );
  }
} 