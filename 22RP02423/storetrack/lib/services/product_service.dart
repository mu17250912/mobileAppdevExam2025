import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/product_model.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<ProductModel> get filteredProducts {
    return _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory && product.isActive;
    }).toList();
  }

  List<ProductModel> get lowStockProducts {
    return _products.where((product) => product.isLowStock && product.isActive).toList();
  }

  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore.collection('products').get();
      _products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(ProductModel product, Uint8List? imageBytes) async {
    try {
      _isLoading = true;
      notifyListeners();

      String? imageUrl;
      if (imageBytes != null) {
        final ref = _storage.ref().child('products/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(imageBytes);
        imageUrl = await ref.getDownloadURL();
      }

      final productWithImage = product.copyWith(
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('products').add(productWithImage.toMap());
      await loadProducts();
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(ProductModel product, Uint8List? imageBytes) async {
    try {
      _isLoading = true;
      notifyListeners();

      String? imageUrl = product.imageUrl;
      if (imageBytes != null) {
        final ref = _storage.ref().child('products/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(imageBytes);
        imageUrl = await ref.getDownloadURL();
      }

      final updatedProduct = product.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('products').doc(product.id).update(updatedProduct.toMap());
      await loadProducts();
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('products').doc(productId).delete();
      await loadProducts();
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStock(String productId, int newQuantity) async {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      final updatedProduct = product.copyWith(
        stockQuantity: newQuantity,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('products').doc(productId).update(updatedProduct.toMap());
      await loadProducts();
      return true;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<String> get categories {
    final categories = _products.map((p) => p.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }
} 