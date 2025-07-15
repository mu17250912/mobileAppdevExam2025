import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; // Fix the import path

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;

  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Authentication methods
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  // Firestore methods for products
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Stream<QuerySnapshot> getProductsStream() {
    return _firestore.collection('products').snapshots();
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    try {
      await _firestore.collection('products').add(product);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Cart methods
  Future<List<Map<String, dynamic>>> getCartItems(String userId) async {
    try {
      final doc = await _firestore.collection('carts').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final items = doc.data()!['items'] as List? ?? [];
        return items.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load cart: $e');
    }
  }

  Future<void> updateCart(String userId, List<Map<String, dynamic>> items) async {
    try {
      await _firestore.collection('carts').doc(userId).set({
        'items': items,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update cart: $e');
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      await _firestore.collection('carts').doc(userId).set({
        'items': [],
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Order methods
  Future<String> createOrder(Map<String, dynamic> orderData) async {
    try {
      final docRef = await _firestore.collection('orders').add({
        ...orderData,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
      
      final orders = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      orders.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      return orders;
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
      
      final pendingOrders = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).where((order) => order['status'] == 'pending').toList();
      pendingOrders.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      return pendingOrders;
    } catch (e) {
      throw Exception('Failed to load pending orders: $e');
    }
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load order: $e');
    }
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  // Payment methods
  Future<void> processPayment(String orderId, Map<String, dynamic> paymentData) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'payment_amount': paymentData['amount'],
        'payment_method': paymentData['method'],
        'payment_status': 'paid',
        'paid_at': DateTime.now().toIso8601String(),
        'status': 'paid',
        'phone_number': paymentData['phone_number'],
        'mobile_money_provider': paymentData['mobile_money_provider'],
      });
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Notification methods
  Future<void> createNotification(Map<String, dynamic> notificationData) async {
    try {
      await _firestore.collection('notifications').add({
        ...notificationData,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'unread',
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      final notifications = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      notifications.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      return notifications;
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': 'read',
        'read_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unread')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // Admin methods
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to load all orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to load all notifications: $e');
    }
  }

  // Initialize sample data
  Future<void> initializeSampleData() async {
    try {
      // Check if products exist
      final productsSnapshot = await _firestore.collection('products').get();
      if (productsSnapshot.docs.isEmpty) {
        // Add sample products
        final sampleProducts = [
          {
            'name': 'NPK 17-17-17 Balanced Fertilizer',
            'category': 'Balanced',
            'price': 2500.0,
            'description': 'Complete balanced fertilizer for all crops',
            'image_url': 'https://example.com/npk.jpg',
            'stock': 1000,
            'unit': 'kg',
          },
          {
            'name': 'Urea Nitrogen Fertilizer',
            'category': 'Nitrogen',
            'price': 1800.0,
            'description': 'High nitrogen fertilizer for leafy growth',
            'image_url': 'https://example.com/urea.jpg',
            'stock': 800,
            'unit': 'kg',
          },
          {
            'name': 'DAP Phosphate Fertilizer',
            'category': 'Phosphate',
            'price': 2200.0,
            'description': 'Phosphate fertilizer for root development',
            'image_url': 'https://example.com/dap.jpg',
            'stock': 600,
            'unit': 'kg',
          },
          {
            'name': 'Potassium Sulfate',
            'category': 'Potassium',
            'price': 2800.0,
            'description': 'Potassium fertilizer for fruit quality',
            'image_url': 'https://example.com/potassium.jpg',
            'stock': 500,
            'unit': 'kg',
          },
          {
            'name': 'Organic Compost',
            'category': 'Organic',
            'price': 1500.0,
            'description': 'Natural organic fertilizer',
            'image_url': 'https://example.com/compost.jpg',
            'stock': 2000,
            'unit': 'kg',
          },
        ];

        for (final product in sampleProducts) {
          await _firestore.collection('products').add(product);
        }
      }
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }
} 