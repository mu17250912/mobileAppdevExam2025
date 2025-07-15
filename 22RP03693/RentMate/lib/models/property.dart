class Property {
  final String id;
  final String landlordId;
  final String title;
  final String description;
  final double monthlyRent;
  final String currency;
  final PropertyType propertyType;
  final int bedrooms;
  final int bathrooms;
  final int squareFootage;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> amenities;
  final String landlordName;
  final String landlordPhone;
  final bool isAvailable;
  final bool isFeatured;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  Property({
    required this.id,
    required this.landlordId,
    required this.title,
    required this.description,
    required this.monthlyRent,
    this.currency = 'RWF',
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFootage,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.amenities,
    required this.landlordName,
    required this.landlordPhone,
    this.isAvailable = true,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      landlordId: json['landlordId'],
      title: json['title'],
      description: json['description'],
      monthlyRent: json['monthlyRent'].toDouble(),
      currency: json['currency'] ?? 'RWF',
      propertyType: PropertyType.values.firstWhere(
        (e) => e.toString() == 'PropertyType.${json['propertyType']}',
      ),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      squareFootage: json['squareFootage'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      images: List<String>.from(json['images']),
      amenities: List<String>.from(json['amenities']),
      landlordName: json['landlordName'],
      landlordPhone: json['landlordPhone'],
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'landlordId': landlordId,
      'title': title,
      'description': description,
      'monthlyRent': monthlyRent,
      'currency': currency,
      'propertyType': propertyType.toString().split('.').last,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFootage': squareFootage,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'amenities': amenities,
      'landlordName': landlordName,
      'landlordPhone': landlordPhone,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Property copyWith({
    String? id,
    String? landlordId,
    String? title,
    String? description,
    double? monthlyRent,
    String? currency,
    PropertyType? propertyType,
    int? bedrooms,
    int? bathrooms,
    int? squareFootage,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? images,
    List<String>? amenities,
    String? landlordName,
    String? landlordPhone,
    bool? isAvailable,
    bool? isFeatured,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
  }) {
    return Property(
      id: id ?? this.id,
      landlordId: landlordId ?? this.landlordId,
      title: title ?? this.title,
      description: description ?? this.description,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      currency: currency ?? this.currency,
      propertyType: propertyType ?? this.propertyType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      squareFootage: squareFootage ?? this.squareFootage,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      landlordName: landlordName ?? this.landlordName,
      landlordPhone: landlordPhone ?? this.landlordPhone,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum PropertyType {
  apartment,
  house,
  studio,
  shared,
  dormitory,
  room,
} 