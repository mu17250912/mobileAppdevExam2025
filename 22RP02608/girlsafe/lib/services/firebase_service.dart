import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseMessaging _messaging;
  late FirebaseAnalytics _analytics;
  late FirebaseStorage _storage;

  // User data
  User? _currentUser;
  String? _fcmToken;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseMessaging get messaging => _messaging;
  FirebaseAnalytics get analytics => _analytics;
  FirebaseStorage get storage => _storage;
  User? get currentUser => _currentUser;
  String? get fcmToken => _fcmToken;

  // Initialize Firebase
  Future<void> initialize() async {
    await Firebase.initializeApp();
    
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _messaging = FirebaseMessaging.instance;
    _analytics = FirebaseAnalytics.instance;
    _storage = FirebaseStorage.instance;

    // Set up auth state listener
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _setupFCM();
        _logUserLogin();
      }
    });

    // Set up FCM message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  // Authentication Methods
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile in Firestore
      await _createUserProfile(credential.user!);
      
      return credential;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _logUserLogin();
      return credential;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _logUserLogout();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // User Profile Management
  Future<void> _createUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isPremium': false,
      'fcmToken': _fcmToken,
    });
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_currentUser != null) {
      await _firestore.collection('users').doc(_currentUser!.uid).update(data);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_currentUser != null) {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      return doc.data();
    }
    return null;
  }

  // Firestore Database Operations
  // Articles
  Future<List<Map<String, dynamic>>> getArticles() async {
    try {
      final snapshot = await _firestore.collection('articles').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting articles: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getArticle(String articleId) async {
    try {
      final doc = await _firestore.collection('articles').doc(articleId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      print('Error getting article: $e');
      return null;
    }
  }

  // Videos
  Future<List<Map<String, dynamic>>> getVideos() async {
    try {
      final snapshot = await _firestore.collection('videos').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting videos: $e');
      return [];
    }
  }

  // Chat Messages
  Future<void> sendChatMessage(String message, String counselorId) async {
    if (_currentUser == null) return;

    await _firestore.collection('chat_messages').add({
      'userId': _currentUser!.uid,
      'counselorId': counselorId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isFromUser': true,
    });
  }

  Stream<QuerySnapshot> getChatMessages(String counselorId) {
    return _firestore
        .collection('chat_messages')
        .where('userId', isEqualTo: _currentUser?.uid)
        .where('counselorId', isEqualTo: counselorId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Reminders
  Future<void> saveReminder(Map<String, dynamic> reminder) async {
    if (_currentUser == null) return;

    await _firestore.collection('reminders').add({
      'userId': _currentUser!.uid,
      ...reminder,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserReminders() async {
    if (_currentUser == null) return [];

    try {
      final snapshot = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: _currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting reminders: $e');
      return [];
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    await _firestore.collection('reminders').doc(reminderId).delete();
  }

  // FCM Setup
  Future<void> _setupFCM() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      
      // Save token to user profile
      if (_currentUser != null && _fcmToken != null) {
        await updateUserProfile({'fcmToken': _fcmToken});
      }
    }
  }

  // Message Handling
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Got a message whilst in the background!');
    print('Message data: ${message.data}');
  }

  // Analytics
  void _logUserLogin() {
    _analytics.logLogin(loginMethod: 'email');
  }

  void _logUserLogout() {
    _analytics.logEvent(name: 'user_logout');
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    Map<String, Object>? convertedParams;
    if (parameters != null) {
      convertedParams = parameters.map((key, value) => MapEntry(key, value as Object));
    }
    await _analytics.logEvent(name: name, parameters: convertedParams);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // File Upload
  Future<String?> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Premium Status
  Future<void> updatePremiumStatus(bool isPremium) async {
    if (_currentUser != null) {
      await updateUserProfile({'isPremium': isPremium});
    }
  }

  Future<bool> getUserPremiumStatus() async {
    final profile = await getUserProfile();
    return profile?['isPremium'] ?? false;
  }
} 