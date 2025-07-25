import 'package:flutter/material.dart';
import '../models/property.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PropertyProvider extends ChangeNotifier {
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _savedSearches = [];
  bool _isLoadingSearches = false;

  List<Property> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get savedSearches => _savedSearches;
  bool get isLoadingSearches => _isLoadingSearches;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load properties from Firestore
  Future<void> loadProperties() async {
    setLoading(true);
    setError(null);
    _loadMockProperties();
    setLoading(false);
  }

  // Load mock properties as fallback
  void _loadMockProperties() {
    _properties = [
      Property(
        id: '1',
        title: 'Modern 3-Bedroom Apartment',
        description: 'Beautiful modern apartment with stunning city views. Recently renovated with high-end finishes.',
        price: 450000,
        propertyType: 'apartment',
        listingType: 'sale',
        bedrooms: 3,
        bathrooms: 2,
        area: 1200,
        address: '123 Main Street, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        images: [
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
          'https://images.unsplash.com/photo-1560448075-bb485b067938?w=800',
          'https://images.unsplash.com/photo-1560448204-603b3fc33ddc?w=800',
        ],
        amenities: ['Parking', 'Gym', 'Pool', 'Balcony'],
        ownerId: 'owner1',
        ownerName: 'John Smith',
        ownerPhone: '+1234567890',
        ownerEmail: 'john@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: true,
        additionalDetails: {},
      ),
      Property(
        id: '2',
        title: 'Cozy 2-Bedroom House',
        description: 'Charming house in a quiet neighborhood. Perfect for families with a large backyard.',
        price: 320000,
        propertyType: 'house',
        listingType: 'sale',
        bedrooms: 2,
        bathrooms: 1,
        area: 1500,
        address: '456 Oak Avenue, Suburbs',
        latitude: 40.7589,
        longitude: -73.9851,
        images: [
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800',
        ],
        amenities: ['Garden', 'Garage', 'Fireplace'],
        ownerId: 'owner2',
        ownerName: 'Sarah Johnson',
        ownerPhone: '+1234567891',
        ownerEmail: 'sarah@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        additionalDetails: {},
      ),
      Property(
        id: '3',
        title: 'Luxury Penthouse for Rent',
        description: 'Exclusive penthouse with panoramic city views. Available for rent with premium amenities.',
        price: 3500,
        propertyType: 'apartment',
        listingType: 'rent',
        bedrooms: 2,
        bathrooms: 2,
        area: 1800,
        address: '789 Luxury Tower, City Center',
        latitude: 40.7505,
        longitude: -73.9934,
        images: [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
          'https://images.unsplash.com/photo-1560448204-603b3fc33ddc?w=800',
          'https://images.unsplash.com/photo-1560448075-bb485b067938?w=800',
        ],
        amenities: ['Concierge', 'Rooftop Pool', 'Gym', 'Parking'],
        ownerId: 'owner3',
        ownerName: 'Michael Brown',
        ownerPhone: '+1234567892',
        ownerEmail: 'michael@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: true,
        additionalDetails: {},
      ),
      // Additional diverse mock properties
      Property(
        id: '4',
        title: 'Beachfront Villa',
        description: 'Stunning villa with private beach access and ocean views.',
        price: 1200000,
        propertyType: 'house',
        listingType: 'sale',
        bedrooms: 5,
        bathrooms: 4,
        area: 3500,
        address: '1 Ocean Drive, Miami Beach',
        latitude: 25.7907,
        longitude: -80.1300,
        images: [
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
          'https://images.unsplash.com/photo-1460518451285-97b6aa326961?w=800',
        ],
        amenities: ['Private Beach', 'Pool', 'Garage', 'Garden', 'Security'],
        ownerId: 'owner4',
        ownerName: 'Anna Lee',
        ownerPhone: '+1234567893',
        ownerEmail: 'anna@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: true,
        additionalDetails: {},
      ),
      Property(
        id: '5',
        title: 'Downtown Studio Loft',
        description: 'Trendy studio loft in the heart of downtown, perfect for young professionals.',
        price: 1800,
        propertyType: 'apartment',
        listingType: 'rent',
        bedrooms: 1,
        bathrooms: 1,
        area: 600,
        address: '22 City Plaza, Downtown',
        latitude: 40.7130,
        longitude: -74.0070,
        images: [
          'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?w=800',
        ],
        amenities: ['Elevator', 'Security', 'Balcony'],
        ownerId: 'owner5',
        ownerName: 'David Kim',
        ownerPhone: '+1234567894',
        ownerEmail: 'david@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        additionalDetails: {},
      ),
      Property(
        id: '6',
        title: 'Suburban Family Home',
        description: 'Spacious family home with a large backyard and modern kitchen.',
        price: 550000,
        propertyType: 'house',
        listingType: 'sale',
        bedrooms: 4,
        bathrooms: 3,
        area: 2500,
        address: '88 Maple Street, Suburbia',
        latitude: 40.7600,
        longitude: -73.9800,
        images: [
          'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?w=800',
        ],
        amenities: ['Garage', 'Garden', 'Fireplace', 'Playground'],
        ownerId: 'owner6',
        ownerName: 'Emily Clark',
        ownerPhone: '+1234567895',
        ownerEmail: 'emily@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        additionalDetails: {},
      ),
      Property(
        id: '7',
        title: 'Commercial Office Space',
        description: 'Modern office space available for rent in a prime business district.',
        price: 8000,
        propertyType: 'commercial',
        listingType: 'rent',
        bedrooms: 0,
        bathrooms: 2,
        area: 5000,
        address: '500 Business Ave, Financial District',
        latitude: 40.7150,
        longitude: -74.0090,
        images: [
          'https://images.unsplash.com/photo-1464983953574-0892a716854b?w=800',
        ],
        amenities: ['Parking', 'Security', 'Elevator', 'Conference Room'],
        ownerId: 'owner7',
        ownerName: 'Olivia Turner',
        ownerPhone: '+1234567896',
        ownerEmail: 'olivia@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        additionalDetails: {},
      ),
      Property(
        id: '8',
        title: 'Vacant Land Plot',
        description: 'Large plot of land suitable for residential or commercial development.',
        price: 300000,
        propertyType: 'land',
        listingType: 'sale',
        bedrooms: 0,
        bathrooms: 0,
        area: 10000,
        address: 'Lot 12, Greenfield Estates',
        latitude: 40.7200,
        longitude: -74.0150,
        images: [
          'https://images.unsplash.com/photo-1507089947368-19c1da9775ae?w=800',
        ],
        amenities: ['None'],
        ownerId: 'owner8',
        ownerName: 'Lucas White',
        ownerPhone: '+1234567897',
        ownerEmail: 'lucas@example.com',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        additionalDetails: {},
      ),
    ];
    notifyListeners();
  }

  // Add new property
  Future<bool> addProperty(Property property) async {
    setLoading(true);
    setError(null);
    
    try {
      // Add to Firestore
      final docRef = await FirebaseFirestore.instance.collection('properties').add({
        'title': property.title,
        'description': property.description,
        'price': property.price,
        'propertyType': property.propertyType,
        'listingType': property.listingType,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'area': property.area,
        'address': property.address,
        'latitude': property.latitude,
        'longitude': property.longitude,
        'images': property.images,
        'amenities': property.amenities,
        'ownerId': property.ownerId,
        'ownerName': property.ownerName,
        'ownerPhone': property.ownerPhone,
        'ownerEmail': property.ownerEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': property.isActive,
        'isFeatured': property.isFeatured,
        'additionalDetails': property.additionalDetails,
      });
      
      // Add to local list with the new ID
      final newProperty = Property(
        id: docRef.id,
        title: property.title,
        description: property.description,
        price: property.price,
        propertyType: property.propertyType,
        listingType: property.listingType,
        bedrooms: property.bedrooms,
        bathrooms: property.bathrooms,
        area: property.area,
        address: property.address,
        latitude: property.latitude,
        longitude: property.longitude,
        images: property.images,
        amenities: property.amenities,
        ownerId: property.ownerId,
        ownerName: property.ownerName,
        ownerPhone: property.ownerPhone,
        ownerEmail: property.ownerEmail,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: property.isActive,
        isFeatured: property.isFeatured,
        additionalDetails: property.additionalDetails,
      );
      
      _properties.insert(0, newProperty);
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to add property: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Get property by ID
  Property? getPropertyById(String id) {
    try {
      return _properties.firstWhere((property) => property.id == id);
    } catch (e) {
      return null;
    }
  }

  // Enhanced filter properties with more options
  List<Property> filterProperties({
    String? propertyType,
    String? listingType,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    int? minBathrooms,
    double? minArea,
    double? maxArea,
    List<String>? amenities,
    String? searchQuery,
    String? location,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isFeatured,
    String? sortBy,
    bool sortDescending = true,
  }) {
    List<Property> filtered = _properties.where((property) {
      // Property type filter
      if (propertyType != null && propertyType != 'all' && property.propertyType != propertyType) {
        return false;
      }
      
      // Listing type filter
      if (listingType != null && listingType != 'all' && property.listingType != listingType) {
        return false;
      }
      
      // Price range filter
      if (minPrice != null && property.price < minPrice) {
        return false;
      }
      if (maxPrice != null && property.price > maxPrice) {
        return false;
      }
      
      // Bedrooms filter
      if (minBedrooms != null && property.bedrooms < minBedrooms) {
        return false;
      }
      if (maxBedrooms != null && property.bedrooms > maxBedrooms) {
        return false;
      }
      
      // Bathrooms filter
      if (minBathrooms != null && property.bathrooms < minBathrooms) {
        return false;
      }
      
      // Area filter
      if (minArea != null && property.area < minArea) {
        return false;
      }
      if (maxArea != null && property.area > maxArea) {
        return false;
      }
      
      // Amenities filter
      if (amenities != null && amenities.isNotEmpty) {
        final hasAllAmenities = amenities.every((amenity) => 
          property.amenities.any((propertyAmenity) => 
            propertyAmenity.toLowerCase().contains(amenity.toLowerCase())
          )
        );
        if (!hasAllAmenities) {
          return false;
        }
      }
      
      // Location filter
      if (location != null && location.isNotEmpty) {
        final locationLower = location.toLowerCase();
        final addressLower = property.address.toLowerCase();
        if (!addressLower.contains(locationLower)) {
          return false;
        }
      }
      
      // Date range filter
      if (dateFrom != null && property.createdAt.isBefore(dateFrom)) {
        return false;
      }
      if (dateTo != null && property.createdAt.isAfter(dateTo)) {
        return false;
      }
      
      // Featured filter
      if (isFeatured != null && property.isFeatured != isFeatured) {
        return false;
      }
      
      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final titleMatch = property.title.toLowerCase().contains(query);
        final descriptionMatch = property.description.toLowerCase().contains(query);
        final addressMatch = property.address.toLowerCase().contains(query);
        final amenitiesMatch = property.amenities.any((amenity) => 
          amenity.toLowerCase().contains(query)
        );
        
        if (!titleMatch && !descriptionMatch && !addressMatch && !amenitiesMatch) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Sort results
    if (sortBy != null) {
      filtered.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'price':
            comparison = a.price.compareTo(b.price);
            break;
          case 'date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'bedrooms':
            comparison = a.bedrooms.compareTo(b.bedrooms);
            break;
          case 'area':
            comparison = a.area.compareTo(b.area);
            break;
          case 'title':
            comparison = a.title.compareTo(b.title);
            break;
          default:
            comparison = a.createdAt.compareTo(b.createdAt);
        }
        return sortDescending ? -comparison : comparison;
      });
    }
    
    return filtered;
  }

  // Load saved searches for current user
  Future<void> loadSavedSearches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setLoadingSearches(true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_searches')
          .orderBy('createdAt', descending: true)
          .get();
      
      _savedSearches = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'filters': Map<String, dynamic>.from(data['filters'] ?? {}),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved searches: $e');
    } finally {
      setLoadingSearches(false);
    }
  }
  
  // Save a search
  Future<bool> saveSearch(String name, Map<String, dynamic> filters) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_searches')
          .add({
        'name': name,
        'filters': filters,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await loadSavedSearches(); // Reload saved searches
      return true;
    } catch (e) {
      debugPrint('Error saving search: $e');
      return false;
    }
  }
  
  // Delete a saved search
  Future<bool> deleteSavedSearch(String searchId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_searches')
          .doc(searchId)
          .delete();
      
      await loadSavedSearches(); // Reload saved searches
      return true;
    } catch (e) {
      debugPrint('Error deleting saved search: $e');
      return false;
    }
  }
  
  void setLoadingSearches(bool loading) {
    _isLoadingSearches = loading;
    notifyListeners();
  }

  // Get featured properties
  List<Property> get featuredProperties {
    return _properties.where((property) => property.isFeatured).toList();
  }

  // Get properties by type
  List<Property> getPropertiesByType(String type) {
    return _properties.where((property) => property.propertyType == type).toList();
  }

  // Get properties for sale
  List<Property> get propertiesForSale {
    return _properties.where((property) => property.listingType == 'sale').toList();
  }

  // Get properties for rent
  List<Property> get propertiesForRent {
    return _properties.where((property) => property.listingType == 'rent').toList();
  }
  
  // Get all available amenities
  List<String> get allAmenities {
    final Set<String> amenities = {};
    for (final property in _properties) {
      amenities.addAll(property.amenities);
    }
    return amenities.toList()..sort();
  }
  
  // Get all property types
  List<String> get allPropertyTypes {
    return _properties.map((p) => p.propertyType).toSet().toList()..sort();
  }
  
  // Get price range
  Map<String, double> get priceRange {
    if (_properties.isEmpty) return {'min': 0, 'max': 1000000};
    
    final prices = _properties.map((p) => p.price).toList();
    return {
      'min': prices.reduce((a, b) => a < b ? a : b),
      'max': prices.reduce((a, b) => a > b ? a : b),
    };
  }
} 