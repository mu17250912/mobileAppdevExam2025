import 'package:flutter/foundation.dart';
import '../models/fruit.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  void addItem(Fruit fruit, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.fruit.id == fruit.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fruit: fruit,
        quantity: quantity,
      ));
    }
    
    notifyListeners();
  }

  void removeItem(String fruitId) {
    _items.removeWhere((item) => item.fruit.id == fruitId);
    notifyListeners();
  }

  void updateQuantity(String fruitId, int quantity) {
    final index = _items.indexWhere((item) => item.fruit.id == fruitId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  CartItem? getItem(String fruitId) {
    try {
      return _items.firstWhere((item) => item.fruit.id == fruitId);
    } catch (e) {
      return null;
    }
  }

  int getQuantity(String fruitId) {
    final item = getItem(fruitId);
    return item?.quantity ?? 0;
  }
}

