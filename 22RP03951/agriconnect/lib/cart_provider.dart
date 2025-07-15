import 'package:flutter/foundation.dart';
import 'cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((element) => element.productId == item.productId);
    
    if (existingIndex >= 0) {
      // Update quantity if item already exists
      final existingItem = _items[existingIndex];
      final updatedItem = CartItem(
        id: existingItem.id,
        productId: existingItem.productId,
        productName: existingItem.productName,
        price: existingItem.price,
        quantity: existingItem.quantity + item.quantity,
        unit: existingItem.unit,
        farmerId: existingItem.farmerId,
        farmerName: existingItem.farmerName,
      );
      _items[existingIndex] = updatedItem;
    } else {
      // Add new item
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, double newQuantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        final item = _items[index];
        final updatedItem = CartItem(
          id: item.id,
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: newQuantity,
          unit: item.unit,
          farmerId: item.farmerId,
          farmerName: item.farmerName,
        );
        _items[index] = updatedItem;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool contains(String productId) {
    return _items.any((item) => item.productId == productId);
  }
} 