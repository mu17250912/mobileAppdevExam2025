import 'package:flutter/material.dart';

class CartService extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];
  double _total = 0.0;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  double get total => _total;
  int get itemCount => _items.length;

  void addItem(Map<String, dynamic> product) {
    final existingIndex = _items.indexWhere((item) => item['id'] == product['id']);
    
    if (existingIndex >= 0) {
      _items[existingIndex]['quantity'] = (_items[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      _items.add({
        ...product,
        'quantity': 1,
      });
    }
    
    _calculateTotal();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item['id'] == productId);
    _calculateTotal();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item['id'] == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index]['quantity'] = quantity;
      }
      _calculateTotal();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _total = 0.0;
    notifyListeners();
  }

  void _calculateTotal() {
    _total = _items.fold(0.0, (sum, item) {
      final price = (item['price'] ?? 0.0).toDouble();
      final quantity = (item['quantity'] ?? 1).toInt();
      return sum + (price * quantity);
    });
  }

  Map<String, dynamic> getItem(String productId) {
    try {
      return _items.firstWhere((item) => item['id'] == productId);
    } catch (e) {
      return {};
    }
  }

  bool hasItem(String productId) {
    return _items.any((item) => item['id'] == productId);
  }
} 