import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Products Collection
  Future<void> addProduct(Map<String, dynamic> product) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .add({
      ...product,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> product) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .doc(productId)
        .update({
      ...product,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .doc(productId)
        .delete();
  }

  Stream<List<Map<String, dynamic>>> getProductsStream() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  // Customers Collection
  Future<void> addCustomer(Map<String, dynamic> customer) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .add({
      ...customer,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCustomer(String customerId, Map<String, dynamic> customer) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .doc(customerId)
        .update({
      ...customer,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCustomer(String customerId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .doc(customerId)
        .delete();
  }

  Stream<List<Map<String, dynamic>>> getCustomersStream() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  // Sales Collection
  Future<void> addSale(Map<String, dynamic> sale) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    await _firestore
        .collection('Sales')
        .add({
      ...sale,
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update product stock
    if (sale['productId'] != null) {
      await updateProductStock(sale['productId'], sale['quantity']);
    }

    // Update customer credit if applicable
    if (sale['customerId'] != null && sale['paymentMethod'] == 'Credit') {
      await updateCustomerCredit(sale['customerId'], sale['totalAmount']);
    }
  }

  Stream<List<Map<String, dynamic>>> getSalesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('Sales')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  // Update product stock after sale
  Future<void> updateProductStock(String productId, int quantitySold) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final productRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .doc(productId);

    await _firestore.runTransaction((transaction) async {
      final productDoc = await transaction.get(productRef);
      if (productDoc.exists) {
        final currentStock = productDoc.data()?['stock'] ?? 0;
        final newStock = currentStock - quantitySold;
        transaction.update(productRef, {'stock': newStock});
      }
    });
  }

  // Update customer credit
  Future<void> updateCustomerCredit(String customerId, int amount) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final customerRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .doc(customerId);

    await _firestore.runTransaction((transaction) async {
      final customerDoc = await transaction.get(customerRef);
      if (customerDoc.exists) {
        final currentCredit = customerDoc.data()?['credit'] ?? 0;
        final newCredit = currentCredit + amount;
        transaction.update(customerRef, {'credit': newCredit});
      }
    });
  }

  // Customer payment
  Future<void> recordCustomerPayment(String customerId, int amount) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    // Add payment transaction
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .doc(customerId)
        .collection('transactions')
        .add({
      'type': 'payment',
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
    });

    // Update customer credit
    final customerRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .doc(customerId);

    await _firestore.runTransaction((transaction) async {
      final customerDoc = await transaction.get(customerRef);
      if (customerDoc.exists) {
        final currentCredit = customerDoc.data()?['credit'] ?? 0;
        final newCredit = currentCredit - amount;
        transaction.update(customerRef, {'credit': newCredit});
      }
    });
  }

  // Get customer transactions
  Stream<List<Map<String, dynamic>>> getCustomerTransactions(String customerId) {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .doc(customerId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  // Analytics and Reports
  Future<Map<String, dynamic>> getBusinessAnalytics() async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    // Get monthly sales
    final salesQuery = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('sales')
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();

    final monthlySales = salesQuery.docs.fold<int>(0, (sum, doc) => sum + (doc.data()['totalAmount'] as int));

    // Get total customers
    final customersQuery = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .get();

    final totalCustomers = customersQuery.docs.length;

    // Get total credit outstanding
    final totalCredit = customersQuery.docs.fold<int>(0, (sum, doc) => sum + (doc.data()['credit'] as int));

    // Get low stock products
    final productsQuery = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .get();

    final lowStockProducts = productsQuery.docs.where((doc) {
      final data = doc.data();
      return (data['stock'] as int) <= (data['minStock'] as int);
    }).length;

    return {
      'monthlySales': monthlySales,
      'totalCustomers': totalCustomers,
      'totalCredit': totalCredit,
      'lowStockProducts': lowStockProducts,
      'totalProducts': productsQuery.docs.length,
    };
  }

  // Search functionality
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (currentUserId == null) return [];
    
    final queryLower = query.toLowerCase();
    final productsQuery = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .get();

    return productsQuery.docs
        .where((doc) {
          final data = doc.data();
          return data['name'].toString().toLowerCase().contains(queryLower) ||
                 data['category'].toString().toLowerCase().contains(queryLower);
        })
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    if (currentUserId == null) return [];
    
    final queryLower = query.toLowerCase();
    final customersQuery = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .get();

    return customersQuery.docs
        .where((doc) {
          final data = doc.data();
          return data['name'].toString().toLowerCase().contains(queryLower) ||
                 data['phone'].toString().contains(query) ||
                 data['email'].toString().toLowerCase().contains(queryLower);
        })
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  // Backup and restore (for offline functionality)
  Future<Map<String, dynamic>> exportData() async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final products = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .get();

    final customers = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('customers')
        .get();

    final sales = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('sales')
        .get();

    return {
      'products': products.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      'customers': customers.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      'sales': sales.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }
} 