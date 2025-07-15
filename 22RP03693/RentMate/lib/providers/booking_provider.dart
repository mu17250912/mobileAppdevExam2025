import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/property.dart';

class BookingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Booking> _bookings = [];

  List<Booking> get bookings => List.unmodifiable(_bookings);

  // Load bookings from Firestore
  Future<void> loadBookings(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      _bookings.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final property = await _getPropertyById(data['propertyId']);
        if (property != null) {
          _bookings.add(Booking.fromJson({
            'id': doc.id,
            ...data,
            'property': property.toJson(),
          }));
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error loading bookings: $e');
    }
  }

  // Add booking to Firestore
  Future<void> addBooking(Property property, {String? message}) async {
    try {
      final bookingData = {
        'propertyId': property.id,
        'status': 'Pending',
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('bookings').add(bookingData);
      
      final booking = Booking(
        property: property,
        status: 'Pending',
        date: DateTime.now(),
        message: message,
      );
      
      _bookings.insert(0, booking);
      notifyListeners();
    } catch (e) {
      print('Error adding booking: $e');
    }
  }

  // Update booking status in Firestore
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        _bookings[index] = Booking(
          property: _bookings[index].property,
          status: newStatus,
          date: _bookings[index].date,
          message: _bookings[index].message,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }

  // Cancel booking in Firestore
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        _bookings[index] = Booking(
          property: _bookings[index].property,
          status: 'Cancelled',
          date: _bookings[index].date,
          message: _bookings[index].message,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error cancelling booking: $e');
    }
  }

  // Get property by ID from Firestore
  Future<Property?> _getPropertyById(String propertyId) async {
    try {
      final doc = await _firestore.collection('properties').doc(propertyId).get();
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

  // Get bookings by landlord
  Future<List<Booking>> getBookingsByLandlord(String landlordId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('landlordId', isEqualTo: landlordId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<Booking> landlordBookings = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final property = await _getPropertyById(data['propertyId']);
        if (property != null) {
          landlordBookings.add(Booking.fromJson({
            'id': doc.id,
            ...data,
            'property': property.toJson(),
          }));
        }
      }
      return landlordBookings;
    } catch (e) {
      print('Error getting landlord bookings: $e');
      return [];
    }
  }
} 