// booking_store.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'car_store.dart';

class Booking {
  final String id;
  final String userId;
  final String carId;
  final String carBrand;
  final String carModel;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropoffLocation;
  final int totalPrice;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? paymentMethod;
  final String? paymentNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.carId,
    required this.carBrand,
    required this.carModel,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.totalPrice,
    this.status = 'pending',
    this.paymentMethod,
    this.paymentNumber,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'carId': carId,
      'carBrand': carBrand,
      'carModel': carModel,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'totalPrice': totalPrice,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentNumber': paymentNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Map
  factory Booking.fromMap(Map<String, dynamic> map, String documentId) {
    return Booking(
      id: documentId,
      userId: (map['userId'] ?? '').toString(),
      carId: (map['carId'] ?? '').toString(),
      carBrand: (map['carBrand'] ?? '').toString(),
      carModel: (map['carModel'] ?? '').toString(),
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['endDate']?.toString() ?? '') ?? DateTime.now(),
      pickupLocation: (map['pickupLocation'] ?? '').toString(),
      dropoffLocation: (map['dropoffLocation'] ?? '').toString(),
      totalPrice: (map['totalPrice'] ?? 0) as int,
      status: (map['status'] ?? 'pending').toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      paymentNumber: map['paymentNumber']?.toString(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }

  // Copy with method for updating booking data
  Booking copyWith({
    String? id,
    String? userId,
    String? carId,
    String? carBrand,
    String? carModel,
    DateTime? startDate,
    DateTime? endDate,
    String? pickupLocation,
    String? dropoffLocation,
    int? totalPrice,
    String? status,
    String? paymentMethod,
    String? paymentNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      carBrand: carBrand ?? this.carBrand,
      carModel: carModel ?? this.carModel,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get formatted dates
  String get formattedStartDate => '${startDate.day}/${startDate.month}/${startDate.year}';
  String get formattedEndDate => '${endDate.day}/${endDate.month}/${endDate.year}';
  String get formattedCreatedAt => '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  
  // Get rental duration in days
  int get durationInDays => endDate.difference(startDate).inDays + 1;
  
  // Get status color
  String get statusDisplayName {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return 'Unknown';
    }
  }
}

class BookingStore {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for real-time updates
  static Stream<List<Booking>> getBookingsStream() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Stream for user-specific bookings (no index required)
  static Stream<List<Booking>> getUserBookingsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Descending
          return bookings;
        });
  }

  // Stream for bookings by status
  static Stream<List<Booking>> getBookingsByStatusStream(String status) {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Get booking by ID
  static Future<Booking?> getBookingById(String id) async {
    try {
      final doc = await _firestore.collection('bookings').doc(id).get();
      if (doc.exists) {
        return Booking.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting booking by ID: $e');
      return null;
    }
  }

  // Create new booking
  static Future<bool> createBooking(Booking booking) async {
    try {
      await _firestore.collection('bookings').doc(booking.id).set(booking.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  // Update booking
  static Future<bool> updateBooking(Booking updatedBooking) async {
    try {
      final updatedData = updatedBooking.copyWith(updatedAt: DateTime.now()).toMap();
      await _firestore.collection('bookings').doc(updatedBooking.id).update(updatedData);
      return true;
    } catch (e) {
      throw Exception('Failed to update booking: ${e.toString()}');
    }
  }

  // Delete booking
  static Future<bool> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete booking: ${e.toString()}');
    }
  }

  // Update booking status
  static Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }
      
      final updatedBooking = booking.copyWith(status: status, updatedAt: DateTime.now());
      return await updateBooking(updatedBooking);
    } catch (e) {
      throw Exception('Failed to update booking status: ${e.toString()}');
    }
  }

  // Stream for bookings by date range
  static Stream<List<Booking>> getBookingsByDateRangeStream(DateTime startDate, DateTime endDate) {
    return _firestore
        .collection('bookings')
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Stream for revenue statistics
  static Stream<Map<String, int>> getRevenueStatisticsStream() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      final bookings = snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
      
      final totalRevenue = bookings
          .where((booking) => booking.status == 'completed')
          .fold(0, (sum, booking) => sum + booking.totalPrice);
      
      final pendingRevenue = bookings
          .where((booking) => booking.status == 'pending')
          .fold(0, (sum, booking) => sum + booking.totalPrice);
      
      final confirmedRevenue = bookings
          .where((booking) => booking.status == 'confirmed')
          .fold(0, (sum, booking) => sum + booking.totalPrice);
      
      return {
        'total': totalRevenue,
        'pending': pendingRevenue,
        'confirmed': confirmedRevenue,
        'totalBookings': bookings.length,
        'completedBookings': bookings.where((booking) => booking.status == 'completed').length,
      };
    });
  }

  // Check if car is available for date range
  static Future<bool> isCarAvailableForDateRange(String carId, DateTime startDate, DateTime endDate, {String? excludeBookingId}) async {
    try {
      Query query = _firestore
          .collection('bookings')
          .where('carId', isEqualTo: carId)
          .where('status', whereIn: ['pending', 'confirmed']); // Only consider active bookings
      
      if (excludeBookingId != null) {
        query = query.where('id', isNotEqualTo: excludeBookingId);
      }
      
      final querySnapshot = await query.get();
      final bookings = querySnapshot.docs.map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      // Allow back-to-back bookings, only block true overlaps
      return !bookings.any((booking) =>
        booking.startDate.isBefore(endDate) && booking.endDate.isAfter(startDate)
      );
    } catch (e) {
      print('Error checking car availability: $e');
      return false;
    }
  }

  // Get booking statistics stream
  static Stream<Map<String, int>> getBookingStatisticsStream() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      final bookings = snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
      
      return {
        'total': bookings.length,
        'pending': bookings.where((booking) => booking.status == 'pending').length,
        'confirmed': bookings.where((booking) => booking.status == 'confirmed').length,
        'completed': bookings.where((booking) => booking.status == 'completed').length,
        'cancelled': bookings.where((booking) => booking.status == 'cancelled').length,
      };
    });
  }

  // Get user booking statistics
  static Stream<Map<String, int>> getUserBookingStatisticsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList();
      
      return {
        'total': bookings.length,
        'pending': bookings.where((booking) => booking.status == 'pending').length,
        'confirmed': bookings.where((booking) => booking.status == 'confirmed').length,
        'completed': bookings.where((booking) => booking.status == 'completed').length,
        'cancelled': bookings.where((booking) => booking.status == 'cancelled').length,
        'totalSpent': bookings
            .where((booking) => booking.status == 'completed')
            .fold(0, (sum, booking) => sum + booking.totalPrice),
      };
    });
  }
} 