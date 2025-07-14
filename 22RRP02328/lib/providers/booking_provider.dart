import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBookingsForUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await BookingService.getBookingsForUser(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBooking(BookingModel booking) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await BookingService.createBooking(booking);
      _bookings.insert(0, booking);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await BookingService.updateBookingStatus(bookingId, status);
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = BookingModel(
          id: _bookings[index].id,
          userId: _bookings[index].userId,
          eventId: _bookings[index].eventId,
          providerId: _bookings[index].providerId,
          fullName: _bookings[index].fullName,
          email: _bookings[index].email,
          phone: _bookings[index].phone,
          serviceType: _bookings[index].serviceType,
          preferredDate: _bookings[index].preferredDate,
          preferredTime: _bookings[index].preferredTime,
          additionalMessage: _bookings[index].additionalMessage,
          requirements: _bookings[index].requirements,
          status: status,
          price: _bookings[index].price,
          place: _bookings[index].place,
          duration: _bookings[index].duration,
          createdAt: _bookings[index].createdAt,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookingsForProvider(String providerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await BookingService.getBookingsForProvider(providerId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _viewMode = 'user'; // 'user' or 'provider'
  String get viewMode => _viewMode;
  void setViewMode(String mode) {
    _viewMode = mode;
    notifyListeners();
  }
} 