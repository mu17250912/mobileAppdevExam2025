import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // Products
  static Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Product.fromJson(doc.data()..['id'] = doc.id)).toList()
    );
  }

  static Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toJson());
  }

  static Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(productId).update(data);
  }

  static Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // Orders
  static Stream<QuerySnapshot<Map<String, dynamic>>> getOrdersForUser(String userId, {bool asFarmer = false}) {
    return _db.collection('orders')
      .where(asFarmer ? 'farmerId' : 'buyerId', isEqualTo: userId)
      .snapshots();
  }

  static Future<void> addOrder(Map<String, dynamic> order) async {
    await _db.collection('orders').add(order);
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllOrders() {
    return _db.collection('orders').snapshots();
  }

  static Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    await _db.collection('orders').doc(orderId).update(data);
  }

  static Future<void> deleteOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).delete();
  }

  // Users
  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) async {
    return await _db.collection('users').doc(userId).get();
  }
} 