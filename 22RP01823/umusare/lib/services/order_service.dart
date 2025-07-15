import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final _firestore = FirebaseFirestore.instance;

  Future<String> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryAddress,
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    final docRef = await _firestore.collection('orders').add({
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    });
    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return {...doc.data()!, 'id': doc.id};
    }
    return null;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({'status': status});
  }
} 