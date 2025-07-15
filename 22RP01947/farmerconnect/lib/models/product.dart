class Product {
  final String id;
  final String name;
  final String description;
  final String location;
  final String harvestDate;
  final int quantity;
  final String unit;
  final int price;
  final String farmerName;
  final String farmerPhone;
  final double rating;
  final String farmerId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.harvestDate,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.farmerName,
    required this.farmerPhone,
    required this.rating,
    required this.farmerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'harvestDate': harvestDate,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'rating': rating,
      'farmerId': farmerId,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      harvestDate: json['harvestDate'],
      quantity: json['quantity'],
      unit: json['unit'],
      price: json['price'],
      farmerName: json['farmerName'],
      farmerPhone: json['farmerPhone'],
      rating: json['rating'].toDouble(),
      farmerId: json['farmerId'] ?? '',
    );
  }
} 