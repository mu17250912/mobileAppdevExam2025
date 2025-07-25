import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Public getter for Firestore instance
  FirebaseFirestore get firestore => _firestore;

  // Collections
  static const String usersCollection = 'users';
  static const String booksCollection = 'books';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String favoritesCollection = 'favorites';
  static const String reviewsCollection = 'reviews';
  static const String notificationsCollection = 'notifications';

  // User Management
  Future<void> createUserProfile(User user, {String? fullName}) async {
    try {
      await _firestore.collection(usersCollection).doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': fullName ?? user.displayName ?? 'Reader',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isPremium': false,
        'trialStartDate': FieldValue.serverTimestamp(),
        'trialEndDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Books Management
  Future<void> addBook(Map<String, dynamic> bookData) async {
    try {
      await _firestore.collection(booksCollection).add({
        ...bookData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add book: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    try {
      final querySnapshot = await _firestore.collection(booksCollection).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get books: $e');
    }
  }

  Future<Map<String, dynamic>?> getBookById(String bookId) async {
    try {
      final doc = await _firestore.collection(booksCollection).doc(bookId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get book: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBooksByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(booksCollection)
          .where('category', isEqualTo: category)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get books by category: $e');
    }
  }

  // Categories Management
  Future<void> addCategory(Map<String, dynamic> categoryData) async {
    try {
      await _firestore.collection(categoriesCollection).add({
        ...categoryData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore.collection(categoriesCollection).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  // Favorites Management
  Future<void> addToFavorites(String userId, Map<String, String> book) async {
    try {
      await _firestore.collection(favoritesCollection).add({
        'userId': userId,
        'book': book,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  Future<void> removeFromFavorites(String userId, Map<String, String> book) async {
    try {
      final querySnapshot = await _firestore
          .collection(favoritesCollection)
          .where('userId', isEqualTo: userId)
          .where('book.title', isEqualTo: book['title'])
          .get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  Future<List<Map<String, String>>> getUserFavorites(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(favoritesCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs
          .map((doc) => Map<String, String>.from(doc.data()['book'] ?? {}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user favorites: $e');
    }
  }

  // Reviews Management
  Future<void> addReview(String userId, String bookId, Map<String, dynamic> reviewData) async {
    try {
      await _firestore.collection(reviewsCollection).add({
        'userId': userId,
        'bookId': bookId,
        ...reviewData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBookReviews(String bookId) async {
    try {
      final querySnapshot = await _firestore
          .collection(reviewsCollection)
          .where('bookId', isEqualTo: bookId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get book reviews: $e');
    }
  }

  // Orders Management
  Future<void> createOrder(String userId, Map<String, dynamic> orderData) async {
    try {
      await _firestore.collection(ordersCollection).add({
        'userId': userId,
        ...orderData,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  // File Upload
  Future<String> uploadImage(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Search Books
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a simple implementation - you might want to use Algolia or similar for better search
      final querySnapshot = await _firestore.collection(booksCollection).get();
      final allBooks = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      return allBooks.where((book) {
        final title = book['title']?.toString().toLowerCase() ?? '';
        final author = book['author']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return title.contains(searchQuery) || author.contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }

  // Notifications Management
  Future<void> createNotification(String userId, Map<String, dynamic> notificationData) async {
    try {
      await _firestore.collection(notificationsCollection).add({
        'userId': userId,
        ...notificationData,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<void> clearAllNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear all notifications: $e');
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread notification count: $e');
    }
  }

  // Create sample notifications for testing
  Future<void> createSampleNotifications(String userId) async {
    try {
      final sampleNotifications = [
        {
          'title': 'New Book Available!',
          'message': 'Check out "The Great Gatsby" - now available in our collection.',
          'type': 'new_book',
        },
        {
          'title': 'Special Promotion',
          'message': 'Get 20% off on all romance novels this week!',
          'type': 'promotion',
        },
        {
          'title': 'Welcome to UMUTONI NOVELS!',
          'message': 'Thank you for joining our community. Start exploring our collection!',
          'type': 'system',
        },
      ];

      for (var notification in sampleNotifications) {
        await createNotification(userId, notification);
      }
    } catch (e) {
      throw Exception('Failed to create sample notifications: $e');
    }
  }
} 