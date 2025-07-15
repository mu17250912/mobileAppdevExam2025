import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../services/property_service.dart';

class PropertyProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PropertyService _propertyService = PropertyService();
  final List<Property> _properties = [];

  List<Property> get properties => List.unmodifiable(_properties);

  // Load properties from Firestore
  Future<void> loadProperties() async {
    try {
      final properties = await _propertyService.getAllProperties();
      _properties.clear();
      _properties.addAll(properties);
    notifyListeners();
    } catch (e) {
      print('Error loading properties: $e');
    }
  }

  // Add property to Firestore
  Future<void> addProperty(Property property) async {
    try {
      final success = await _propertyService.addProperty(property);
      if (success) {
        await loadProperties(); // Reload properties
      }
    } catch (e) {
      print('Error adding property: $e');
    }
  }

  // Remove property from Firestore
  Future<void> removeProperty(String propertyId) async {
    try {
      final success = await _propertyService.deleteProperty(propertyId);
      if (success) {
    _properties.removeWhere((p) => p.id == propertyId);
    notifyListeners();
      }
    } catch (e) {
      print('Error removing property: $e');
    }
  }

  // Update property in Firestore
  Future<void> updateProperty(Property updatedProperty) async {
    try {
      final success = await _propertyService.updateProperty(updatedProperty);
      if (success) {
    final index = _properties.indexWhere((p) => p.id == updatedProperty.id);
    if (index != -1) {
      _properties[index] = updatedProperty;
      notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating property: $e');
    }
  }

  // Clear properties
  void clear() {
    _properties.clear();
    notifyListeners();
  }

  // Seed sample properties to Firestore
  Future<void> seedSampleProperties() async {
    try {
      await _propertyService.seedSampleProperties();
      await loadProperties(); // Reload properties after seeding
    } catch (e) {
      print('Error seeding sample properties: $e');
    }
  }

  // Get properties by landlord
  Future<List<Property>> getPropertiesByLandlord(String landlordId) async {
    try {
      return await _propertyService.getPropertiesByLandlord(landlordId);
    } catch (e) {
      print('Error getting landlord properties: $e');
      return [];
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
      return await _propertyService.searchProperties(
        query: query,
        minPrice: minPrice,
        maxPrice: maxPrice,
        amenities: amenities,
        location: location,
        propertyType: propertyType,
      );
    } catch (e) {
      print('Error searching properties: $e');
      return [];
    }
  }

  // Get featured properties
  Future<List<Property>> getFeaturedProperties() async {
    try {
      return await _propertyService.getFeaturedProperties();
    } catch (e) {
      print('Error getting featured properties: $e');
      return [];
    }
  }
} 