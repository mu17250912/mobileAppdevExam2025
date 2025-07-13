import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new product
  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore.collection('Products').doc(product.id).set(product.toMap());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Get all products (for buyers)
  Stream<List<ProductModel>> getAllProducts() {
    return _firestore
        .collection('Products')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromMap(data);
      }).toList();
    });
  }

  // Get products by seller ID
  Stream<List<ProductModel>> getProductsBySeller(String sellerId) {
    return _firestore
        .collection('Products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromMap(data);
      }).toList();
    });
  }

  // Update a product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore.collection('Products').doc(product.id).update(product.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('Products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get a single product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('Products').doc(productId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return ProductModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Get user data from users collection
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Stream user data from users collection
  Stream<Map<String, dynamic>?> getUserDataStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Stream all users (for admin)
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Order methods
  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore.collection('Orders').doc(order.id).set(order.toMap());
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get orders by seller
  Stream<List<OrderModel>> getOrdersBySeller(String sellerId) {
    return _firestore
        .collection('Orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromMap(data);
      }).toList();
    });
  }

  // Get orders by buyer
  Stream<List<OrderModel>> getOrdersByBuyer(String buyerId) {
    return _firestore
        .collection('Orders')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromMap(data);
      }).toList();
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status, {String? rejectionReason}) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }
      await _firestore.collection('Orders').doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  // Update order with MoMo account number
  Future<void> updateOrderWithMomoAccount(String orderId, String momoAccountNumber) async {
    try {
      await _firestore.collection('Orders').doc(orderId).update({
        'buyerMomoAccount': momoAccountNumber,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update order with MoMo account: $e');
    }
  }

  // Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('Orders').doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // Process payment and update order status
  Future<void> processPayment(String orderId, String productId, double quantity) async {
    try {
      // Get the order
      final orderDoc = await _firestore.collection('Orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      final orderData = orderDoc.data()!;
      final order = OrderModel.fromMap(orderData);
      
      // Get the product to update inventory
      final productDoc = await _firestore.collection('Products').doc(productId).get();
      if (!productDoc.exists) {
        throw Exception('Product not found');
      }
      
      final productData = productDoc.data()!;
      final currentQuantity = (productData['quantity'] ?? 0).toDouble();
      
      if (currentQuantity < quantity) {
        throw Exception('Insufficient inventory');
      }
      
      // Calculate commission and payout
      final totalAmount = order.totalAmount;
      final commission = totalAmount * 0.053; // 5.3% commission
      final payout = totalAmount - commission; // Seller payout
      
      // Update product inventory
      await _firestore.collection('Products').doc(productId).update({
        'quantity': currentQuantity - quantity,
      });
      
      // Update order status to accepted and mark as paid
      await _firestore.collection('Orders').doc(orderId).update({
        'status': 'accepted',
        'paymentStatus': 'paid',
        'commission': commission, // Update with actual commission
        'payout': payout, // Update with actual payout
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Record commission payment
      await _firestore.collection('CommissionPayments').add({
        'orderId': orderId,
        'productId': productId,
        'sellerId': order.sellerId,
        'buyerId': order.buyerId,
        'totalAmount': totalAmount,
        'commission': commission,
        'payout': payout,
        'paymentDate': DateTime.now().toIso8601String(),
        'status': 'completed',
      });
      
      // Create notification for seller
      final sellerNotification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_seller_payment',
        userId: order.sellerId,
        title: 'Payment Received - Commission Deducted',
        message: 'Payment of ${totalAmount.toStringAsFixed(0)} RWF received for ${order.quantity}kg of ${order.productName}. Your payout: ${payout.toStringAsFixed(0)} RWF (${commission.toStringAsFixed(0)} RWF commission deducted)',
        type: 'payment_received',
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      await createNotification(sellerNotification);
      
      // Create notification for buyer
      final buyerNotification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_buyer_payment',
        userId: order.buyerId,
        title: 'Payment Successful',
        message: 'Your payment of ${totalAmount.toStringAsFixed(0)} RWF has been processed successfully.',
        type: 'payment_successful',
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      await createNotification(buyerNotification);
      
      // Create commission notification for admin users
      final adminUsers = await _firestore.collection('users')
          .where('role', isEqualTo: 'Admin')
          .get();
      
      for (final adminDoc in adminUsers.docs) {
        final adminNotification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_admin_commission_${adminDoc.id}',
          userId: adminDoc.id,
          title: '💰 Commission Payment Received',
          message: 'Commission: ${commission.toStringAsFixed(0)} RWF\nOrder: #${orderId} (${order.productName}, ${order.quantity}kg)\nSeller: ${order.sellerName}\nBuyer: ${order.buyerName}\nOrder Value: ${totalAmount.toStringAsFixed(0)} RWF',
          type: 'commission_received',
          isRead: false,
          createdAt: DateTime.now(),
        );
        await createNotification(adminNotification);
      }
      // Create summary notification for admin about total commission
      final totalCommissionQuery = await _firestore.collection('CommissionPayments').get();
      final totalCommission = totalCommissionQuery.docs.fold<double>(
        0, (sum, doc) => sum + (doc.data()['commission'] ?? 0).toDouble()
      );
      for (final adminDoc in adminUsers.docs) {
        final summaryNotification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_admin_summary_${adminDoc.id}',
          userId: adminDoc.id,
          title: '📊 Commission Summary',
          message: 'Total Commission: ${totalCommission.toStringAsFixed(0)} RWF\nPayments: ${totalCommissionQuery.docs.length}\nAvg/Payment: ${totalCommissionQuery.docs.isNotEmpty ? (totalCommission / totalCommissionQuery.docs.length).toStringAsFixed(0) : '0'} RWF\nLatest: ${commission.toStringAsFixed(0)} RWF from #${orderId}',
          type: 'commission_summary',
          isRead: false,
          createdAt: DateTime.now(),
        );
        await createNotification(summaryNotification);
      }
      
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Notification methods
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('Notifications').doc(notification.id).set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get notifications by user
  Stream<List<NotificationModel>> getNotificationsByUser(String userId) {
    return _firestore
        .collection('Notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromMap(data);
      }).toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('Notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Admin: Create a new user
  Future<void> createUser(UserModel user, String password) async {
    // This is a placeholder. In production, you would use Firebase Admin SDK or a Cloud Function to create users securely.
    // For now, just add to Firestore (not secure for real auth, but works for demo data).
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  // Admin: Update user
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  // Admin: Delete user
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // Admin: Change user role
  Future<void> changeUserRole(String userId, String newRole) async {
    await _firestore.collection('users').doc(userId).update({'role': newRole});
  }

  // Get commission payment records (for admin)
  Stream<List<Map<String, dynamic>>> getCommissionPayments() {
    return _firestore
        .collection('CommissionPayments')
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get commission payments by date range (for admin)
  Future<List<Map<String, dynamic>>> getCommissionPaymentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('CommissionPayments')
          .where('paymentDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('paymentDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get commission payments: $e');
    }
  }

  // Get all admin users
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get admin users: $e');
    }
  }

  // Public method to fetch a single order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('Orders').doc(orderId).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return OrderModel.fromMap(data);
    }
    return null;
  }
} 