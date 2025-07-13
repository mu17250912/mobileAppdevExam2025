class Property {
  final String id;
  final String title;
  final String description;
  final String address;
  final double price;
  final String status; // 'available', 'rented', etc.
  final String imageUrl;
  final String ownerId;
  final String category;
  final List<String> amenities;
  final int bedrooms;
  final int bathrooms;
  final String propertyType; // 'rent' or 'sale'

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.price,
    required this.status,
    required this.imageUrl,
    required this.ownerId,
    required this.category,
    required this.amenities,
    required this.bedrooms,
    required this.bathrooms,
    required this.propertyType,
  });

  factory Property.fromMap(Map<String, dynamic> data, String documentId) {
    return Property(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'available',
      imageUrl: data['imageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      category: data['category'] ?? '',
      amenities: List<String>.from(data['amenities'] ?? []),
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      propertyType: data['propertyType'] ?? 'rent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'address': address,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'category': category,
      'amenities': amenities,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'propertyType': propertyType,
    };
  }
}
