import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all properties
  Future<List<Property>> getAllProperties() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('properties').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting properties: $e');
      return [];
    }
  }

  // Get properties by landlord
  Future<List<Property>> getPropertiesByLandlord(String landlordId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('properties')
          .where('landlordId', isEqualTo: landlordId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting landlord properties: $e');
      return [];
    }
  }

  // Get property by ID
  Future<Property?> getPropertyById(String propertyId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('properties').doc(propertyId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromJson({
          'id': doc.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      print('Error getting property: $e');
      return null;
    }
  }

  // Search properties
  Future<List<Property>> searchProperties({
    String? query,
    double? minPrice,
    double? maxPrice,
    List<String>? amenities,
    String? location,
    PropertyType? propertyType,
  }) async {
    try {
      Query queryRef = _firestore.collection('properties');

      // Apply filters
      if (minPrice != null) {
        queryRef = queryRef.where('monthlyRent', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        queryRef = queryRef.where('monthlyRent', isLessThanOrEqualTo: maxPrice);
      }

      if (propertyType != null) {
        queryRef = queryRef.where('propertyType', isEqualTo: propertyType.toString().split('.').last);
      }

      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('address', isGreaterThanOrEqualTo: location)
            .where('address', isLessThan: location + '\uf8ff');
      }

      final QuerySnapshot snapshot = await queryRef.get();
      List<Property> properties = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();

      // Apply additional filters that can't be done in Firestore query
      if (query != null && query.isNotEmpty) {
        properties = properties.where((property) =>
          property.title.toLowerCase().contains(query.toLowerCase()) ||
          property.description.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }

      if (amenities != null && amenities.isNotEmpty) {
        properties = properties.where((property) =>
          amenities.every((amenity) => property.amenities.contains(amenity))
        ).toList();
      }

      return properties;
    } catch (e) {
      print('Error searching properties: $e');
      return [];
    }
  }

  // Add new property
  Future<bool> addProperty(Property property) async {
    try {
      final propertyData = property.toJson();
      propertyData.remove('id'); // Remove id as Firestore will generate it
      
      await _firestore.collection('properties').add(propertyData);
      print('Property added: ${property.title}');
      return true;
    } catch (e) {
      print('Error adding property: $e');
      return false;
    }
  }

  // Update property
  Future<bool> updateProperty(Property property) async {
    try {
      final propertyData = property.toJson();
      propertyData.remove('id'); // Remove id as we're updating by id
      
      await _firestore.collection('properties').doc(property.id).update(propertyData);
      print('Property updated: ${property.title}');
      return true;
    } catch (e) {
      print('Error updating property: $e');
      return false;
    }
  }

  // Delete property
  Future<bool> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).delete();
      print('Property deleted: $propertyId');
      return true;
    } catch (e) {
      print('Error deleting property: $e');
      return false;
    }
  }

  // Get featured properties
  Future<List<Property>> getFeaturedProperties() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('properties')
          .where('isFeatured', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting featured properties: $e');
      return [];
    }
  }

  // Get properties by type
  Future<List<Property>> getPropertiesByType(PropertyType type) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('properties')
          .where('propertyType', isEqualTo: type.toString().split('.').last)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting properties by type: $e');
      return [];
    }
  }

  // Seed sample properties to Firestore
  Future<void> seedSampleProperties() async {
    try {
      final properties = [
      Property(
          id: 'property_1',
          landlordId: 'landlord_1',
          title: 'Smart City Apartment',
          description: 'A modern, tech-enabled apartment with smart home features and mobile app access.',
          monthlyRent: 80000,
          propertyType: PropertyType.apartment,
          bedrooms: 2,
        bathrooms: 1,
          squareFootage: 850,
          address: '123 Main St, Downtown',
          latitude: 0.0,
          longitude: 0.0,
        images: [
            'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=800&q=80',
        ],
          amenities: ['WiFi', 'Smart Lock', 'App Control'],
          landlordName: 'John Doe',
        landlordPhone: '+1234567890',
        isAvailable: true,
        isFeatured: true,
          rating: 4.8,
        reviewCount: 12,
          createdAt: DateTime.now(),
      ),
      Property(
          id: 'property_2',
          landlordId: 'landlord_1',
          title: 'App-Connected Studio',
          description: 'Studio with app-controlled lighting, security, and climate. Perfect for students.',
          monthlyRent: 120000,
          propertyType: PropertyType.studio,
          bedrooms: 1,
          bathrooms: 1,
          squareFootage: 400,
          address: '456 College Ave, University District',
          latitude: 0.0,
          longitude: 0.0,
        images: [
            'https://images.unsplash.com/photo-1503389152951-9c3d0456e63e?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
        ],
          amenities: ['WiFi', 'App Lighting', 'Security'],
          landlordName: 'Jane Smith',
        landlordPhone: '+1234567891',
        isAvailable: true,
          isFeatured: false,
          rating: 4.5,
        reviewCount: 8,
          createdAt: DateTime.now(),
      ),
      Property(
          id: 'property_3',
          landlordId: 'landlord_1',
          title: 'Connected Family Home',
          description: 'Spacious home with smart thermostat, app-enabled entry, and family-friendly tech.',
          monthlyRent: 200000,
          propertyType: PropertyType.house,
          bedrooms: 4,
        bathrooms: 2,
          squareFootage: 1800,
          address: '789 Oak Lane, Suburbia',
          latitude: 0.0,
          longitude: 0.0,
        images: [
            'https://images.unsplash.com/photo-1519974719765-e6559eac2575?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=800&q=80',
        ],
          amenities: ['Smart Thermostat', 'App Entry', 'Garden'],
          landlordName: 'Alice Brown',
        landlordPhone: '+1234567892',
        isAvailable: true,
          isFeatured: true,
          rating: 4.9,
        reviewCount: 15,
          createdAt: DateTime.now(),
      ),
      Property(
          id: 'property_4',
          landlordId: 'landlord_1',
          title: 'Luxury Penthouse Suite',
          description: 'Penthouse with panoramic views, app-controlled blinds, and luxury tech amenities.',
          monthlyRent: 3500,
        propertyType: PropertyType.apartment,
          bedrooms: 3,
          bathrooms: 2,
          squareFootage: 1400,
          address: '1010 Skyline Blvd, Downtown',
          latitude: 0.0,
          longitude: 0.0,
          images: [
            'https://images.unsplash.com/photo-1507089947368-19c1da9775ae?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          ],
          amenities: ['WiFi', 'App Blinds', 'Pool'],
          landlordName: 'Chris Green',
          landlordPhone: '+1234567893',
          isAvailable: true,
          isFeatured: true,
          rating: 5.0,
          reviewCount: 20,
          createdAt: DateTime.now(),
        ),
        Property(
          id: 'property_5',
          landlordId: 'landlord_1',
          title: 'Affordable Shared Room',
          description: 'Budget-friendly room in a smart home, with app-enabled laundry and WiFi.',
          monthlyRent: 400,
          propertyType: PropertyType.room,
        bedrooms: 1,
        bathrooms: 1,
          squareFootage: 200,
          address: '202 Shared St, Student Village',
          latitude: 0.0,
          longitude: 0.0,
        images: [
            'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1503389152951-9c3d0456e63e?auto=format&fit=crop&w=800&q=80',
        ],
          amenities: ['WiFi', 'App Laundry'],
          landlordName: 'Sam Lee',
          landlordPhone: '+1234567894',
        isAvailable: true,
        isFeatured: false,
          rating: 4.2,
          reviewCount: 5,
          createdAt: DateTime.now(),
        ),
      ];

      // Add properties to Firestore
      for (final property in properties) {
        final propertyData = property.toJson();
        propertyData.remove('id'); // Remove id as Firestore will generate it
        await _firestore.collection('properties').add(propertyData);
      }

      print('Sample properties seeded successfully');
    } catch (e) {
      print('Error seeding sample properties: $e');
    }
  }
} 