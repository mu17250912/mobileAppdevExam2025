import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/order.dart' as model_order;

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _cartDocId; // Firestore doc id for the current cart

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  // Firestore integration
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> loadUnpaidCart() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final query = await _firestore
        .collection('carts')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'unpaid')
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      _cartDocId = doc.id;
      final data = doc.data();
      final itemsMap = data['items'] as Map<String, dynamic>?;
      _items.clear();
      if (itemsMap != null) {
        for (final entry in itemsMap.entries) {
          // You may want to fetch product details from Firestore if needed
          final productId = entry.key;
          final itemData = entry.value;
          // For now, just store quantity, you can enhance this to fetch product
          _items[productId] = CartItem(
            product: Product(
              id: productId,
              name: itemData['name'] ?? '',
              price: (itemData['price'] ?? 0).toDouble(),
              description: itemData['description'] ?? '',
              imageUrl: itemData['imageUrl'] ?? '',
              category: itemData['category'] ?? '',
              isAvailable: true,
              unit: itemData['unit'] ?? '',
              stockQuantity: (itemData['stockQuantity'] ?? 0.0).toDouble(),
            ),
            quantity: itemData['quantity'] ?? 1,
          );
        }
      }
      notifyListeners();
    }
  }

  Future<void> _saveCartToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final cartData = {
      'userId': user.uid,
      'status': 'unpaid',
      'items': _items.map((key, item) => MapEntry(key, {
        'name': item.product.name,
        'price': item.product.price,
        'description': item.product.description,
        'imageUrl': item.product.imageUrl,
        'category': item.product.category,
        'quantity': item.quantity,
      })),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (_cartDocId != null) {
      await _firestore.collection('carts').doc(_cartDocId).set(cartData);
    } else {
      final docRef = await _firestore.collection('carts').add(cartData);
      _cartDocId = docRef.id;
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          product: product,
          quantity: 1,
        ),
      );
    }
    _saveCartToFirestore();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveCartToFirestore();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
    } else if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: quantity,
        ),
      );
      _saveCartToFirestore();
      notifyListeners();
    }
  }

  Future<void> markCartAsPaid() async {
    if (_cartDocId != null) {
      await _firestore.collection('carts').doc(_cartDocId).update({'status': 'paid'});
    }
    clear(localOnly: true);
  }

  Future<void> saveOrder({
    required String address,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null || _items.isEmpty) {
      return;
    }
    final order = model_order.Order(
      id: '',
      userId: user.uid,
      items: _items.values.toList(),
      total: totalAmount,
      date: DateTime.now(),
      status: 'pending',
      address: address,
      phone: phone,
    );
    try {
      await _firestore.collection('orders').add(order.toMap());
    } catch (e) {
      // Handle error silently
    }
  }

  void clear({bool localOnly = false}) {
    _items.clear();
    if (!localOnly) _saveCartToFirestore();
    notifyListeners();
    _cartDocId = null;
  }
} 