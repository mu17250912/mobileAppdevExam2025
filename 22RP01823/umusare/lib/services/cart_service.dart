import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _cartItems = [];
  final StreamController<List<CartItem>> _cartController = StreamController<List<CartItem>>.broadcast();
  static const String _cartKey = 'cart_items';

  Stream<List<CartItem>> get cartStream => _cartController.stream;
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  int get itemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(0)} RWF';

  // Load cart data from SharedPreferences
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);
      if (cartData != null) {
        final List<dynamic> cartJson = json.decode(cartData);
        _cartItems.clear();
        for (final itemJson in cartJson) {
          _cartItems.add(CartItem.fromJson(itemJson));
        }
        _notifyListeners();
      }
    } catch (e) {
      // If there's an error loading cart data, start with empty cart
      _cartItems.clear();
      _notifyListeners();
    }
  }

  // Save cart data to SharedPreferences
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = _cartItems.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, json.encode(cartJson));
    } catch (e) {
      // Handle save error silently
    }
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex != -1) {
      // Update existing item quantity
      final existingItem = _cartItems[existingIndex];
      _cartItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Add new item
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }
    
    _notifyListeners();
    _saveCart(); // Save to persistent storage
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    _notifyListeners();
    _saveCart(); // Save to persistent storage
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      final existingItem = _cartItems[index];
      _cartItems[index] = existingItem.copyWith(quantity: newQuantity);
      _notifyListeners();
      _saveCart(); // Save to persistent storage
    }
  }

  void incrementQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      final existingItem = _cartItems[index];
      _cartItems[index] = existingItem.copyWith(quantity: existingItem.quantity + 1);
      _notifyListeners();
      _saveCart(); // Save to persistent storage
    }
  }

  void decrementQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      final existingItem = _cartItems[index];
      if (existingItem.quantity > 1) {
        _cartItems[index] = existingItem.copyWith(quantity: existingItem.quantity - 1);
      } else {
        removeFromCart(productId);
      }
      _notifyListeners();
      _saveCart(); // Save to persistent storage
    }
  }

  void clearCart() {
    _cartItems.clear();
    _notifyListeners();
    _saveCart(); // Save to persistent storage
  }

  CartItem? getCartItem(String productId) {
    try {
      return _cartItems.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  bool isInCart(String productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }

  void _notifyListeners() {
    _cartController.add(List.unmodifiable(_cartItems));
  }

  void dispose() {
    _cartController.close();
  }
} 