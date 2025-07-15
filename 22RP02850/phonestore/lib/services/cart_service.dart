import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/order.dart' as app_order;
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's cart items
  Stream<List<CartItem>> getCartItems() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItem.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Add item to cart
  Future<void> addToCart(CartItem item) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final cartRef = _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(item.productId);

    final existingDoc = await cartRef.get();

    if (existingDoc.exists) {
      // Update quantity if item already exists
      final existingData = existingDoc.data()!;
      final currentQuantity = existingData['quantity'] ?? 0;
      await cartRef.update({
        'quantity': currentQuantity + item.quantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      // Add new item
      await cartRef.set(item.toMap());
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (quantity <= 0) {
      // Remove item if quantity is 0 or negative
      await removeFromCart(productId);
    } else {
      await _firestore
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(productId)
          .update({
        'quantity': quantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(productId)
        .delete();
  }

  // Clear entire cart
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final cartRef = _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items');

    final snapshot = await cartRef.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Get cart total
  Future<double> getCartTotal() async {
    final items = await getCartItems().first;
    double total = 0.0;
    for (final item in items) {
      total += item.totalPrice;
    }
    return total;
  }

  // Get cart item count
  Future<int> getCartItemCount() async {
    final items = await getCartItems().first;
    int count = 0;
    for (final item in items) {
      count += item.quantity;
    }
    return count;
  }

  // Create order from cart
  Future<app_order.Order> createOrder({
    required String paymentMethod,
    required String? paymentId,
    double tax = 0.0,
    double shipping = 0.0,
    String status = 'pending', // <-- Add status parameter
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final items = await getCartItems().first;
    if (items.isEmpty) throw Exception('Cart is empty');

    double subtotal = 0.0;
    for (final item in items) {
      subtotal += item.totalPrice;
    }
    final total = subtotal + tax + shipping;

    // Collect all unique sellerIds from the items
    final sellerIds = items.map((item) => item.sellerId).toSet().toList();

    final orderRef = _firestore.collection('orders').doc();
    final order = app_order.Order(
      id: orderRef.id,
      userId: user.uid,
      userEmail: user.email ?? '',
      items: items,
      sellerIds: sellerIds,
      subtotal: subtotal,
      tax: tax,
      shipping: shipping,
      total: total,
      status: status, // <-- Use status parameter
      paymentMethod: paymentMethod,
      paymentId: paymentId,
      createdAt: DateTime.now(),
    );

    // Save the order with sellerIds array
    await orderRef.set({
      ...order.toMap(),
      'sellerIds': sellerIds,
    });

    // Clear cart after successful order creation
    await clearCart();

    return order;
  }

  // Get user's order history
  Stream<List<app_order.Order>> getUserOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.Order.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> placeOrder(app_order.Order order) async {
    try {
      // Create the order document
      final orderDoc = await _firestore.collection('orders').add(order.toMap());
      
      // Clear the cart
      await clearCart();
      
      // Send notification to the user about order confirmation
      await NotificationService.sendNotificationToUser(
        userId: order.userId,
        title: 'Order Confirmed!',
        body: 'Your order #${orderDoc.id.substring(0, 8)} has been placed successfully.',
        type: 'order_update',
        data: {
          'orderId': orderDoc.id,
          'status': order.status,
        },
      );
      
      // Send notifications to all sellers involved in the order
      for (String sellerId in order.sellerIds) {
        await NotificationService.sendNotificationToUser(
          userId: sellerId,
          title: 'New Order Received!',
          body: 'You have received a new order with ${order.items.length} items.',
          type: 'order_update',
          data: {
            'orderId': orderDoc.id,
            'buyerId': order.userId,
          },
        );
      }
    } catch (e) {
      rethrow;
    }
  }
} 