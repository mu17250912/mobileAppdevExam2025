import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final String propertyType; // house, apartment, land, commercial
  final String listingType; // sale, rent
  final int bedrooms;
  final int bathrooms;
  final double area; // in square feet/meters
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> amenities;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isFeatured;
  final Map<String, dynamic> additionalDetails;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.propertyType,
    required this.listingType,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.amenities,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isFeatured,
    required this.additionalDetails,
  });

  factory Property.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Property(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      propertyType: data['propertyType'] ?? '',
      listingType: data['listingType'] ?? '',
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      area: (data['area'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      amenities: List<String>.from(data['amenities'] ?? []),
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerPhone: data['ownerPhone'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      additionalDetails: Map<String, dynamic>.from(data['additionalDetails'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'propertyType': propertyType,
      'listingType': listingType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'amenities': amenities,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerEmail': ownerEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isFeatured': isFeatured,
      'additionalDetails': additionalDetails,
    };
  }

  Property copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? propertyType,
    String? listingType,
    int? bedrooms,
    int? bathrooms,
    double? area,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? images,
    List<String>? amenities,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isFeatured,
    Map<String, dynamic>? additionalDetails,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      additionalDetails: additionalDetails ?? this.additionalDetails,
    );
  }

  String get formattedPrice {
    return '\$${price.toStringAsFixed(0)}';
  }

  String get formattedArea {
    return '${area.toStringAsFixed(0)} sq ft';
  }

  String get propertyTypeDisplay {
    switch (propertyType.toLowerCase()) {
      case 'house':
        return 'House';
      case 'apartment':
        return 'Apartment';
      case 'land':
        return 'Land';
      case 'commercial':
        return 'Commercial';
      default:
        return propertyType;
    }
  }

  String get listingTypeDisplay {
    return listingType == 'sale' ? 'For Sale' : 'For Rent';
  }
} 