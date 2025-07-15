/// Professional Booking Service for SafeRide
///
/// This service handles all booking-related operations including creating,
/// updating, and managing ride bookings with proper error handling and
/// real-time updates.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../models/payment_method.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      _firestore.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection('rides');
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Create a new booking
  Future<BookingModel> createBooking({
    required String rideId,
    required int seatsBooked,
    required String pickupLocation,
    required String dropoffLocation,
    String? specialRequests,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get ride details
      final rideDoc = await _ridesCollection.doc(rideId).get();
      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data()!;
      final ride = RideModel.fromMap({...rideData, 'id': rideDoc.id});

      // Check if ride is still available
      if (ride.availableSeats < seatsBooked) {
        throw Exception('Not enough seats available');
      }

      // Check if user already has a booking for this ride
      final existingBooking = await _bookingsCollection
          .where('rideId', isEqualTo: rideId)
          .where('passengerId', isEqualTo: currentUser.uid)
          .where('status', whereIn: [
        BookingStatus.pending.name,
        BookingStatus.confirmed.name
      ]).get();

      if (existingBooking.docs.isNotEmpty) {
        throw Exception('You already have a booking for this ride');
      }

      // Create booking document
      final bookingData = {
        'rideId': rideId,
        'passengerId': currentUser.uid,
        'driverId': ride.driverId,
        'seatsBooked': seatsBooked,
        'totalAmount': ride.price * seatsBooked,
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'specialRequests': specialRequests ?? '',
        'paymentMethod': paymentMethod.name,
        'status': BookingStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'departureTime': ride.departureTime,
        'origin': {
          'name': ride.origin.name,
          'latitude': ride.origin.latitude,
          'longitude': ride.origin.longitude,
        },
        'destination': {
          'name': ride.destination.name,
          'latitude': ride.destination.latitude,
          'longitude': ride.destination.longitude,
        },
      };

      final bookingDoc = await _bookingsCollection.add(bookingData);
      final bookingId = bookingDoc.id;

      // Update ride available seats
      await _ridesCollection.doc(rideId).update({
        'availableSeats': FieldValue.increment(-seatsBooked),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the created booking
      final createdBookingDoc = await _bookingsCollection.doc(bookingId).get();
      return BookingModel.fromMap(
          {...createdBookingDoc.data()!, 'id': bookingId});
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get all bookings for a specific user
  Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    return _bookingsCollection
        .where('passengerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Get all bookings for a specific user (one-time)
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final snapshot = await _bookingsCollection
          .where('passengerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data != null) {
          return BookingModel.fromMap(
              {...(data as Map<String, dynamic>), 'id': doc.id});
        } else {
          return BookingModel.fromMap({'id': doc.id});
        }
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message != null &&
          e.message!.contains('index')) {
        // Handle missing index error gracefully
        print('⚠️ Firestore index not ready yet. Returning empty list.');
        return [];
      } else if (e.code == 'permission-denied') {
        throw Exception('Access denied. Please check your permissions.');
      } else if (e.code == 'unavailable') {
        throw Exception(
            'Service temporarily unavailable. Please try again later.');
      } else {
        throw Exception('Failed to load bookings: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error in getUserBookings: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Get all bookings for a specific driver
  Stream<List<BookingModel>> getDriverBookingsStream(String driverId) async* {
    try {
      await for (final snapshot in _bookingsCollection
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        yield snapshot.docs
            .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList();
      }
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message != null &&
          e.message!.contains('index')) {
        // Handle missing index error gracefully
        yield [];
        // Optionally, log or notify the user
      } else {
        rethrow;
      }
    }
  }

  /// Get all bookings for a specific ride
  Stream<List<BookingModel>> getRideBookingsStream(String rideId) async* {
    try {
      await for (final snapshot in _bookingsCollection
          .where('rideId', isEqualTo: rideId)
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        yield snapshot.docs
            .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList();
      }
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message != null &&
          e.message!.contains('index')) {
        // Handle missing index error gracefully
        yield [];
        // Optionally, log or notify the user
      } else {
        rethrow;
      }
    }
  }

  /// Get a specific booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return BookingModel.fromMap({...data, 'id': doc.id});
        } else {
          return BookingModel.fromMap({'id': doc.id});
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? reason,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        updateData['statusReason'] = reason;
      }

      await _bookingsCollection.doc(bookingId).update(updateData);

      // If booking is cancelled, restore seats to ride
      if (status == BookingStatus.cancelled) {
        final booking = await getBookingById(bookingId);
        if (booking != null) {
          await _ridesCollection.doc(booking.rideId).update({
            'availableSeats': FieldValue.increment(booking.seatsBooked),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      // Check if booking can be cancelled
      if (booking.status == BookingStatus.completed ||
          booking.status == BookingStatus.cancelled) {
        throw Exception('Booking cannot be cancelled');
      }

      // Update booking status
      await updateBookingStatus(bookingId, BookingStatus.cancelled,
          reason: reason);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Complete a booking
  Future<void> completeBooking(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      if (booking.status != BookingStatus.confirmed) {
        throw Exception('Booking must be confirmed before completion');
      }

      await updateBookingStatus(bookingId, BookingStatus.completed);
    } catch (e) {
      throw Exception('Failed to complete booking: $e');
    }
  }

  /// Get booking statistics for a user
  Future<Map<String, dynamic>> getUserBookingStats(String userId) async {
    try {
      final bookings = await getUserBookings(userId);

      int totalBookings = bookings.length;
      int activeBookings = bookings
          .where((b) =>
              b.status == BookingStatus.pending ||
              b.status == BookingStatus.confirmed)
          .length;
      int completedBookings =
          bookings.where((b) => b.status == BookingStatus.completed).length;
      int cancelledBookings =
          bookings.where((b) => b.status == BookingStatus.cancelled).length;

      double totalSpent = bookings
          .where((b) => b.status == BookingStatus.completed)
          .fold(0.0, (total, booking) => total + booking.totalAmount);

      return {
        'totalBookings': totalBookings,
        'activeBookings': activeBookings,
        'completedBookings': completedBookings,
        'cancelledBookings': cancelledBookings,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      throw Exception('Failed to get booking statistics: $e');
    }
  }

  /// Get booking statistics for a driver
  Future<Map<String, dynamic>> getDriverBookingStats(String driverId) async {
    try {
      final snapshot = await _bookingsCollection
          .where('driverId', isEqualTo: driverId)
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data != null) {
          return BookingModel.fromMap(
              {...(data as Map<String, dynamic>), 'id': doc.id});
        } else {
          return BookingModel.fromMap({'id': doc.id});
        }
      }).toList();

      int totalBookings = bookings.length;
      int activeBookings = bookings
          .where((b) =>
              b.status == BookingStatus.pending ||
              b.status == BookingStatus.confirmed)
          .length;
      int completedBookings =
          bookings.where((b) => b.status == BookingStatus.completed).length;

      double totalEarnings = bookings
          .where((b) => b.status == BookingStatus.completed)
          .fold(0.0, (total, booking) => total + booking.totalAmount);

      return {
        'totalBookings': totalBookings,
        'activeBookings': activeBookings,
        'completedBookings': completedBookings,
        'totalEarnings': totalEarnings,
      };
    } catch (e) {
      throw Exception('Failed to get driver booking statistics: $e');
    }
  }

  /// Search bookings with filters
  Future<List<BookingModel>> searchBookings({
    String? userId,
    String? driverId,
    String? rideId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _bookingsCollection;

      if (userId != null) {
        query = query.where('passengerId', isEqualTo: userId);
      }

      if (driverId != null) {
        query = query.where('driverId', isEqualTo: driverId);
      }

      if (rideId != null) {
        query = query.where('rideId', isEqualTo: rideId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data != null) {
          return BookingModel.fromMap(
              {...(data as Map<String, dynamic>), 'id': doc.id});
        } else {
          return BookingModel.fromMap({'id': doc.id});
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to search bookings: $e');
    }
  }

  /// Get recent bookings for dashboard
  Future<List<BookingModel>> getRecentBookings(String userId,
      {int limit = 5}) async {
    try {
      final snapshot = await _bookingsCollection
          .where('passengerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data != null) {
          return BookingModel.fromMap(
              {...(data as Map<String, dynamic>), 'id': doc.id});
        } else {
          return BookingModel.fromMap({'id': doc.id});
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to get recent bookings: $e');
    }
  }

  /// Check if user has active booking for a ride
  Future<bool> hasActiveBooking(String userId, String rideId) async {
    try {
      final snapshot = await _bookingsCollection
          .where('passengerId', isEqualTo: userId)
          .where('rideId', isEqualTo: rideId)
          .where('status', whereIn: [
        BookingStatus.pending.name,
        BookingStatus.confirmed.name
      ]).get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get booking with ride and user details
  Future<Map<String, dynamic>?> getBookingWithDetails(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) return null;

      // Get ride details
      final rideDoc = await _ridesCollection.doc(booking.rideId).get();
      final ride = rideDoc.exists
          ? RideModel.fromMap({...rideDoc.data()!, 'id': rideDoc.id})
          : null;

      // Get passenger details
      final passengerDoc =
          await _usersCollection.doc(booking.passengerId).get();
      final passenger = passengerDoc.exists
          ? UserModel.fromMap(passengerDoc.data()!, passengerDoc.id)
          : null;

      // Get driver details
      final driverDoc = await _usersCollection.doc(booking.driverId).get();
      final driver = driverDoc.exists
          ? UserModel.fromMap(driverDoc.data()!, driverDoc.id)
          : null;

      return {
        'booking': booking,
        'ride': ride,
        'passenger': passenger,
        'driver': driver,
      };
    } catch (e) {
      throw Exception('Failed to get booking details: $e');
    }
  }
}
