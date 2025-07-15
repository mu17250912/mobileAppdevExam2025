class ProductModel {
  final String id;
  final String name;
  final double quantity;
  final double pricePerKg;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String sellerDistrict;
  final String sellerSector;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.pricePerKg,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerDistrict,
    required this.sellerSector,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'sellerDistrict': sellerDistrict,
      'sellerSector': sellerSector,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      pricePerKg: (map['pricePerKg'] ?? 0).toDouble(),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? 'Unknown',
      sellerPhone: map['sellerPhone'] ?? 'N/A',
      sellerDistrict: map['sellerDistrict'] ?? 'N/A',
      sellerSector: map['sellerSector'] ?? 'N/A',
      createdAt: map['createdAt'] != null && map['createdAt'] != '' ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updatedAt'] != null && map['updatedAt'] != '' ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now() : DateTime.now(),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? quantity,
    double? pricePerKg,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerDistrict,
    String? sellerSector,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerDistrict: sellerDistrict ?? this.sellerDistrict,
      sellerSector: sellerSector ?? this.sellerSector,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 