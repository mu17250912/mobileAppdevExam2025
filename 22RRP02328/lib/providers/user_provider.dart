import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  List<UserModel> _serviceProviders = [];
  bool _isLoading = false;
  String? _error;
  List<UserModel> _allUsers = [];

  // Getters
  UserModel? get currentUser => _currentUser;
  List<UserModel> get serviceProviders => _serviceProviders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserModel> get allUsers => _allUsers;

  // Set current user
  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Load user data
  Future<void> loadUserData(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentUser = await AuthService.getUserData(userId);
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      await AuthService.updateUserData(_currentUser!.id, data);
      await loadUserData(_currentUser!.id);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load service providers
  Future<void> loadServiceProviders() async {
    _setLoading(true);
    _clearError();
    try {
      final all = await AuthService.getAllUsers();
      _serviceProviders = all.where((u) => u.userType == AppConstants.userTypeServiceProvider).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load all users from Firestore
  Future<void> loadAllUsers() async {
    _setLoading(true);
    _clearError();
    try {
      _allUsers = await AuthService.getAllUsers();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get service providers by category
  List<UserModel> getServiceProvidersByCategory(String category) {
    return _serviceProviders.where((provider) {
      return provider.services?.contains(category) ?? false;
    }).toList();
  }

  // Search service providers
  List<UserModel> searchServiceProviders(String query) {
    if (query.isEmpty) return _serviceProviders;
    
    return _serviceProviders.where((provider) {
      return provider.name.toLowerCase().contains(query.toLowerCase()) ||
             (provider.bio != null && provider.bio!.toLowerCase().contains(query.toLowerCase())) ||
             (provider.location != null && provider.location!.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Set error
  void _setError(String error) {
    _error = error;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear error
  void _clearError() {
    _error = null;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
} 