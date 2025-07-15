import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  String? _userType;
  bool _loading = true;
  String? _subscriptionPlan = 'Basic'; // Default subscription plan
  String? _subscriptionStatus = 'active'; // Default status
  final AuthService _authService = AuthService();

  Map<String, dynamic>? get userData => _userData;
  String? get userType => _userType;
  bool get loading => _loading;
  String? get subscriptionPlan => _subscriptionPlan;
  String? get subscriptionStatus => _subscriptionStatus;

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    print('UserProvider: fetchUserData called, user: ${user?.email}');
    
    if (user == null) {
      print('UserProvider: No user found, setting loading to false');
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      print('UserProvider: Fetching user data from Firestore...');
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      print('UserProvider: Firestore document exists: ${doc.exists}');
      
      if (doc.exists) {
        _userData = doc.data();
        _userType = _userData?['userType'] ?? 'Farmer';
        _subscriptionPlan = _userData?['subscriptionPlan'] ?? 'Basic';
        _subscriptionStatus = _userData?['subscriptionStatus'] ?? 'active';
        print('UserProvider: User data loaded - userType: $_userType, subscriptionPlan: $_subscriptionPlan, subscriptionStatus: $_subscriptionStatus');
      } else {
        // If user doesn't exist in Firestore, create default profile
        print('UserProvider: User not found in Firestore, creating default profile');
        _userType = 'Farmer'; // Default
        _subscriptionPlan = 'Basic';
        _subscriptionStatus = 'active';
        await _createDefaultUserProfile(user);
      }
    } catch (e) {
      print('UserProvider: Error fetching user data: $e');
      _userType = 'Farmer'; // Default
      _subscriptionPlan = 'Basic';
      _subscriptionStatus = 'active';
    }

    _loading = false;
    print('UserProvider: Notifying listeners, userType: $_userType');
    notifyListeners();
  }

  Future<void> _createDefaultUserProfile(User user) async {
    try {
      print('UserProvider: Creating default user profile for ${user.email}');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'userType': 'Farmer',
        'subscriptionPlan': 'Basic',
        'subscriptionStatus': 'active',
        'creationTime': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      _userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'userType': 'Farmer',
        'subscriptionPlan': 'Basic',
        'subscriptionStatus': 'active',
      };
      print('UserProvider: Default profile created successfully');
    } catch (e) {
      print('UserProvider: Error creating default user profile: $e');
    }
  }

  Future<void> updateUserType(String userType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      print('UserProvider: Updating user type to: $userType');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'userType': userType,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      _userType = userType;
      if (_userData != null) {
        _userData!['userType'] = userType;
      }
      print('UserProvider: User type updated successfully');
      notifyListeners();
    } catch (e) {
      print('UserProvider: Error updating user type: $e');
    }
  }

  Future<void> updateSubscriptionPlan(String plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String status = 'active';
      if (plan == 'Premium' || plan == 'Enterprise') {
        status = 'pending';
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'subscriptionPlan': plan,
        'subscriptionStatus': status,
        'subscriptionUpdatedAt': DateTime.now().toIso8601String(),
      });
      
      _subscriptionPlan = plan;
      _subscriptionStatus = status;
      if (_userData != null) {
        _userData!['subscriptionPlan'] = plan;
        _userData!['subscriptionStatus'] = status;
      }
      notifyListeners();
    } catch (e) {
      print('Error updating subscription plan: $e');
    }
  }

  bool isPremiumUser() {
    return _subscriptionPlan == 'Premium' && _subscriptionStatus == 'active';
  }

  bool isEnterpriseUser() {
    return _subscriptionPlan == 'Enterprise' && _subscriptionStatus == 'active';
  }

  bool isFarmer() {
    return _userType == 'Farmer';
  }

  bool isBuyer() {
    return _userType == 'Buyer';
  }

  bool isAdmin() {
    return _userType == 'Admin';
  }

  String getUserTypeDisplayName() {
    switch (_userType) {
      case 'Farmer':
        return 'Farmer';
      case 'Buyer':
        return 'Buyer';
      case 'Admin':
        return 'Administrator';
      default:
        return 'User';
    }
  }

  String getSubscriptionDisplayName() {
    switch (_subscriptionPlan) {
      case 'Basic':
        return 'Basic Plan';
      case 'Premium':
        return 'Premium Plan';
      case 'Enterprise':
        return 'Enterprise Plan';
      default:
        return 'Basic Plan';
    }
  }

  void clearUserData() {
    _userData = null;
    _userType = null;
    _subscriptionPlan = 'Basic';
    _subscriptionStatus = 'active';
    _loading = false;
    notifyListeners();
  }
} 