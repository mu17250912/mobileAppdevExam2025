import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Call this on app start
  Future<void> loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await fetchUserProfile(user.uid);
    }
  }

  Future<void> fetchUserProfile(String uid) async {
    setLoading(true);
    try {
      print('Fetching user profile for uid: $uid');
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      print('User doc exists: ${doc.exists}');
      if (doc.exists) {
        print('User doc data: \n${doc.data()}');
        _currentUser = UserModel.fromFirestore(doc);
        print('UserModel loaded: \n');
        notifyListeners();
      } else {
        // If user doc does not exist, create a default profile
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          final userDoc = {
            'fullName': firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
            'email': firebaseUser.email ?? '',
            'phone': firebaseUser.phoneNumber ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'userType': 'buyer',
            'favorites': [],
            'savedSearches': [],
            'preferences': {},
            'isVerified': false,
            'isActive': true,
          };
          print('Creating default user doc: \n$userDoc');
          await FirebaseFirestore.instance.collection('users').doc(uid).set(userDoc);
          final newDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          _currentUser = UserModel.fromFirestore(newDoc);
          print('UserModel loaded after creation: \n');
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error in fetchUserProfile: $e');
      setError('Failed to load user profile:  ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    if (error != null) print('AuthProvider error: $error');
    notifyListeners();
  }

  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Real login method using Firebase Auth and Firestore
  Future<bool> login(String email, String password) async {
    setLoading(true);
    setError(null);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await fetchUserProfile(credential.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Login failed:  ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Real register method (optional: can be updated similarly)
  Future<bool> register(String email, String password, String fullName, String userType) async {
    setLoading(true);
    setError(null);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final userDoc = {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userType': userType,
        'favorites': [],
        'savedSearches': [],
        'preferences': {},
        'isVerified': false,
        'isActive': true,
        'role': 'user',
      };
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set(userDoc);
      await fetchUserProfile(credential.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Registration failed:  ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    setLoading(true);
    try {
      await FirebaseAuth.instance.signOut();
      setUser(null);
    } catch (e) {
      setError('Logout failed:  ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void addToFavorites(String propertyId) {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        favorites: [..._currentUser!.favorites, propertyId],
      );
      setUser(updatedUser);
    }
  }

  void removeFromFavorites(String propertyId) {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        favorites: _currentUser!.favorites.where((id) => id != propertyId).toList(),
      );
      setUser(updatedUser);
    }
  }

  bool isFavorite(String propertyId) {
    return _currentUser?.favorites.contains(propertyId) ?? false;
  }
} 