import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../utils/constants.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createBooking(BookingModel booking) async {
    await _firestore
        .collection(AppConstants.bookingsCollection)
        .doc(booking.id)
        .set(booking.toJson());
  }

  static Future<List<BookingModel>> getBookingsForUser(String userId) async {
    final query = await _firestore
        .collection(AppConstants.bookingsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => BookingModel.fromJson(doc.data())).toList();
  }

  static Future<List<BookingModel>> getBookingsForProvider(String providerId) async {
    final query = await _firestore
        .collection(AppConstants.bookingsCollection)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => BookingModel.fromJson(doc.data())).toList();
  }

  static Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId)
        .update({'status': status, 'updatedAt': DateTime.now().toIso8601String()});
  }
} 