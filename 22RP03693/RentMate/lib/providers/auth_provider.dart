import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import '../models/property.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  List<String> _favoritePropertyIds = [];
  final List<Booking> _bookings = [];

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  List<String> get favoritePropertyIds => _favoritePropertyIds;
  List<Booking> get bookings => _bookings;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to get current user from Firebase Auth
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        // Load user's bookings
        await _loadUserBookings(user.id);
      }
    } catch (e) {
      print('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final user = await _authService.getUserById(_currentUser!.id);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  Future<void> _loadUserBookings(String userId) async {
    try {
      // This would be implemented in a booking service
      // For now, we'll keep the local booking list
      print('Loading bookings for user: $userId');
    } catch (e) {
      print('Error loading user bookings: $e');
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserType userType,
    String? university,
    String? studentId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        userType: userType,
        university: university,
        studentId: studentId,
      );

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return null; // null means success
      }
      _isLoading = false;
      notifyListeners();
      return 'Registration failed. Please try again.';
    } catch (e) {
      print('Error signing up: $e');
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        // Load user's bookings
        await _loadUserBookings(user.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _bookings.clear();
      _favoritePropertyIds.clear();
    } catch (e) {
      print('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
    String? university,
    String? studentId,
  }) async {
    if (_currentUser == null) return false;

    try {
      final success = await _authService.updateUserProfile(
        name: name,
        phone: phone,
        profileImage: profileImage,
        university: university,
        studentId: studentId,
      );

      if (success) {
        // Refresh current user
        final updatedUser = await _authService.getCurrentUser();
        if (updatedUser != null) {
          _currentUser = updatedUser;
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  bool isFavorite(String propertyId) => _favoritePropertyIds.contains(propertyId);

  void addFavorite(String propertyId) {
    if (!_favoritePropertyIds.contains(propertyId)) {
      _favoritePropertyIds.add(propertyId);
      notifyListeners();
    }
  }

  void removeFavorite(String propertyId) {
    if (_favoritePropertyIds.contains(propertyId)) {
      _favoritePropertyIds.remove(propertyId);
      notifyListeners();
    }
  }

  void addBooking(Property property) {
    final booking = Booking(
      property: property,
      status: 'Approved',
      date: DateTime.now(),
    );
    _bookings.add(booking);
    notifyListeners();
  }
} 