import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

// UserProfile class (if not already defined elsewhere)
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? businessName;
  final double defaultVATRate;
  final DateTime createdAt;
  final bool premium; // Added premium flag

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.businessName,
    this.defaultVATRate = 0.18,
    required this.createdAt,
    this.premium = false, // Default to false
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      businessName: json['businessName'],
      defaultVATRate: (json['defaultVATRate'] as num?)?.toDouble() ?? 0.18,
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is DateTime)
              ? json['createdAt'] as DateTime
              : DateTime.now(),
      premium: json['premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'businessName': businessName,
        'defaultVATRate': defaultVATRate,
        'createdAt': createdAt,
        'premium': premium,
      };

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? businessName,
    double? defaultVATRate,
    DateTime? createdAt,
    bool? premium,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      defaultVATRate: defaultVATRate ?? this.defaultVATRate,
      createdAt: createdAt ?? this.createdAt,
      premium: premium ?? this.premium,
    );
  }
}

class AppState extends ChangeNotifier {
  fb_auth.User? _currentUser;
  UserProfile? _userProfile;
  FirebaseFirestore? _firestore;
  fb_auth.FirebaseAuth? _auth;
  bool _isInitialized = false;
  bool _isFirebaseInitialized = false;

  // Getters
  fb_auth.User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;

  // Updated constructor to accept Firebase initialization status
  AppState({bool isFirebaseInitialized = false}) {
    _isFirebaseInitialized = isFirebaseInitialized;
    _initializeFirebase();
  }

  // Simplified Firebase initialization since it's already done in main.dart
  Future<void> _initializeFirebase() async {
    try {
      // Firebase is already initialized in main.dart, just get instances
      _firestore = FirebaseFirestore.instance;
      _auth = fb_auth.FirebaseAuth.instance;
      
      // Listen to auth state changes
      _auth!.authStateChanges().listen((user) {
        _currentUser = user;
        if (user != null) {
          _loadUserProfile();
        } else {
          _userProfile = null;
        }
        notifyListeners();
      });
      
      _isInitialized = true;
      print('[AppState] Firebase services initialized successfully');
      notifyListeners();
    } catch (e) {
      print('[AppState] Firebase services initialization error: $e');
      _isInitialized = true; // Mark as initialized even if failed
      notifyListeners();
    }
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      if (_currentUser != null && _firestore != null) {
        final doc = await _firestore!
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        
        if (doc.exists) {
          _userProfile = UserProfile.fromJson(doc.data()!);
        } else {
          // Create default profile if doesn't exist
          _userProfile = UserProfile(
            id: _currentUser!.uid,
            name: _currentUser!.displayName ?? 'User',
            email: _currentUser!.email ?? '',
            createdAt: DateTime.now(),
          );
          await _createUserProfile(_userProfile!);
        }
        notifyListeners();
      }
    } catch (e) {
      print('[AppState] Error loading user profile: $e');
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(UserProfile profile) async {
    try {
      await _firestore!
          .collection('users')
          .doc(profile.id)
          .set(profile.toJson());
    } catch (e) {
      print('[AppState] Error creating user profile: $e');
    }
  }

  // Authentication methods
  Future<void> login(String email, String password) async {
    try {
      await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('[AppState] Login error: $e');
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String? businessName, String password) async {
    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);
        
        // Create user profile
        final profile = UserProfile(
          id: credential.user!.uid,
          name: name,
          email: email,
          businessName: businessName,
          createdAt: DateTime.now(),
        );
        
        await _createUserProfile(profile);
        _userProfile = profile;
        notifyListeners();
      }
    } catch (e) {
      print('[AppState] Signup error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth!.signOut();
      // Also sign out from Google
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      print('[AppState] Logout error: $e');
      rethrow;
    }
  }

  // Google Sign-In method
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth!.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Check if user profile exists, if not create one
        final doc = await _firestore!
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (!doc.exists) {
          // Create new user profile for Google user
          final profile = UserProfile(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'User',
            email: userCredential.user!.email ?? '',
            createdAt: DateTime.now(),
          );
          await _createUserProfile(profile);
        }
      }
    } catch (e) {
      print('[AppState] Google Sign-In error: $e');
      rethrow;
    }
  }

  // Profile management
  Future<void> updateProfile({
    String? name,
    String? businessName,
    double? defaultVATRate,
  }) async {
    try {
      if (_userProfile != null && _firestore != null) {
        final updatedProfile = _userProfile!.copyWith(
          name: name,
          businessName: businessName,
          defaultVATRate: defaultVATRate,
        );
        
        await _firestore!
            .collection('users')
            .doc(_userProfile!.id)
            .update(updatedProfile.toJson());
        
        _userProfile = updatedProfile;
        notifyListeners();
      }
    } catch (e) {
      print('[AppState] Error updating profile: $e');
      rethrow;
    }
  }

  // Document management
  Future<Document?> createDocument({
    required DocumentType type,
    required ClientInfo clientInfo,
    required List<DocumentItem> items,
    required double subtotal,
    required double discount,
    required double vatRate,
    required double vatAmount,
    required double total,
    required DocumentStatus status,
    required DateTime createdDate,
    DateTime? createdAt,
    DateTime? dueDate,
  }) async {
    try {
      if (_firestore != null && _currentUser != null) {
        final docRef = _firestore!
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('documents')
            .doc();
        final documentWithId = Document(
          id: docRef.id,
          type: type,
          number: '', // You may want to generate a number here
          clientInfo: clientInfo,
          items: items,
          subtotal: subtotal,
          discount: discount,
          vatRate: vatRate,
          vatAmount: vatAmount,
          total: total,
          status: status,
          createdDate: createdDate,
          createdAt: createdAt ?? DateTime.now(),
          dueDate: dueDate,
          userId: _currentUser!.uid,
        );
        await docRef.set(documentWithId.toJson());
        print('[AppState] Document created successfully');
        // --- Add notification logic ---
        String notifTitle = '';
        String notifMsg = '';
        if (status == DocumentStatus.pending) {
          notifTitle = 'Document Pending';
          notifMsg = 'A new document is pending approval.';
        } else if (status == DocumentStatus.paid) {
          notifTitle = 'Payment Received';
          notifMsg = 'A document has been marked as paid.';
        } else if (status == DocumentStatus.overdue) {
          notifTitle = 'Payment Overdue';
          notifMsg = 'A document is overdue for payment.';
        }
        if (notifTitle.isNotEmpty) {
          final notification = NotificationItem(
            id: '',
            title: notifTitle,
            message: notifMsg,
            timestamp: DateTime.now(),
            read: false,
          );
          await addNotification(notification);
        }
        // --- End notification logic ---
        return documentWithId;
      }
      return null;
    } catch (e) {
      print('[AppState] Error creating document: $e');
      rethrow;
    }
  }

  Future<Document?> getDocumentById(String documentId) async {
    try {
      if (_firestore != null && _currentUser != null) {
        final doc = await _firestore!
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('documents')
            .doc(documentId)
            .get();
        if (doc.exists) {
          return Document.fromJson(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      print('[AppState] Error getting document: $e');
      return null;
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      if (_firestore != null && _currentUser != null) {
        await _firestore!
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('documents')
            .doc(documentId)
            .delete();
        print('[AppState] Document deleted successfully');
      }
    } catch (e) {
      print('[AppState] Error deleting document: $e');
      rethrow;
    }
  }

  Future<void> updateDocumentStatus(String documentId, DocumentStatus status) async {
    if (_firestore != null && _currentUser != null) {
      await _firestore!
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('documents')
        .doc(documentId)
        .update({'status': status.toString().split('.').last});
    }
  }

  Future<void> updateDocument(Document document) async {
    if (_firestore != null && _currentUser != null) {
      await _firestore!
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('documents')
        .doc(document.id)
        .update(document.toJson());
    }
  }

  Stream<List<Document>> documentsStream() {
    if (_firestore == null || _currentUser == null) {
      return Stream.value([]);
    }
    return _firestore!
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('documents')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Document.fromJson(doc.data()))
          .toList();
    });
  }

  // Notifications
  Stream<List<NotificationItem>> notificationsStream() {
    if (_firestore == null || _currentUser == null) {
      return Stream.value([]);
    }
    return _firestore!
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationItem.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> addNotification(NotificationItem notification) async {
    if (_firestore != null && _currentUser != null) {
      await _firestore!
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('notifications')
          .add(notification.toJson());
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (_firestore != null && _currentUser != null) {
      await _firestore!
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    }
  }

  // Helper methods
  Future<void> refreshUserProfile() async {
    await _loadUserProfile();
  }

  void dispose() {
    super.dispose();
  }
}