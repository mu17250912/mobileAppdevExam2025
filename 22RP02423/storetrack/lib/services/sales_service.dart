import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';

class SalesService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<SaleModel> _sales = [];
  List<SaleItem> _currentCart = [];
  bool _isLoading = false;

  List<SaleModel> get sales => _sales;
  List<SaleItem> get currentCart => _currentCart;
  bool get isLoading => _isLoading;

  double get cartSubtotal {
    return _currentCart.fold(0, (sum, item) => sum + item.total);
  }

  double get cartTax => cartSubtotal * 0.1; // 10% tax
  double get cartTotal => cartSubtotal + cartTax;

  Future<void> loadSales() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore.collection('sales').orderBy('createdAt', descending: true).get();
      _sales = snapshot.docs
          .map((doc) => SaleModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading sales: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSalesByCashier(String cashierId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('sales')
          .where('cashierId', isEqualTo: cashierId)
          .orderBy('createdAt', descending: true)
          .get();
      
      _sales = snapshot.docs
          .map((doc) => SaleModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading sales by cashier: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(ProductModel product, int quantity) async {
    try {
      final existingIndex = _currentCart.indexWhere((item) => item.productId == product.id);
      
      if (existingIndex != -1) {
        final existingItem = _currentCart[existingIndex];
        final newQuantity = existingItem.quantity + quantity;
        final newTotal = product.price * newQuantity;
        
        _currentCart[existingIndex] = SaleItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: newQuantity,
          total: newTotal,
        );
      } else {
        _currentCart.add(SaleItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: quantity,
          total: product.price * quantity,
        ));
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  void removeFromCart(String productId) {
    _currentCart.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int quantity) {
    final index = _currentCart.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      final item = _currentCart[index];
      if (quantity <= 0) {
        _currentCart.removeAt(index);
      } else {
        _currentCart[index] = SaleItem(
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: quantity,
          total: item.price * quantity,
        );
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _currentCart.clear();
    notifyListeners();
  }

  Future<bool> completeSale(SaleModel sale) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_currentCart.isEmpty) {
        return false;
      }

      await _firestore.collection('sales').add(sale.toMap());
      
      // Update product stock
      for (final item in _currentCart) {
        // This would typically update the product stock in ProductService
        // For now, we'll just clear the cart
      }

      _currentCart.clear();
      await loadSales();
      
      return true;
    } catch (e) {
      print('Error completing sale: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getTodaySales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _sales
        .where((sale) => sale.createdAt.isAfter(startOfDay))
        .fold(0, (sum, sale) => sum + sale.total);
  }

  double getTodaySalesByCashier(String cashierId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _sales
        .where((sale) => 
            sale.createdAt.isAfter(startOfDay) && 
            sale.cashierId == cashierId)
        .fold(0, (sum, sale) => sum + sale.total);
  }

  int getTodayTransactionCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _sales
        .where((sale) => sale.createdAt.isAfter(startOfDay))
        .length;
  }

  int getTodayTransactionCountByCashier(String cashierId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _sales
        .where((sale) => 
            sale.createdAt.isAfter(startOfDay) && 
            sale.cashierId == cashierId)
        .length;
  }
} 