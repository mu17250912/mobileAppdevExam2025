import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');

  // Fetch all products (real-time)
  Stream<List<Product>> getProductsStream() {
    return _productsCollection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>)).toList()
    );
  }

  // Fetch all products (one-time)
  Future<List<Product>> getProducts() async {
    final snapshot = await _productsCollection.get();
    return snapshot.docs.map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  // Fetch products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    if (category.toLowerCase() == 'all') {
      return getProducts();
    }
    final snapshot = await _productsCollection.where('category', isEqualTo: category).get();
    return snapshot.docs.map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  // Add a new product
  Future<void> addProduct(Product product) async {
    final docRef = await _productsCollection.add(product.toJson());
    await docRef.update({'id': docRef.id});
  }

  // Update an existing product
  Future<void> updateProduct(Product product) async {
    await _productsCollection.doc(product.id).update(product.toJson());
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    final doc = await _productsCollection.doc(id).get();
    if (doc.exists) {
      return Product.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
} 