import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/product_model.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'package:intl/intl.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      setState(() {
        _currentUserId = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  void _showStockUpdateDialog(Product product) {
    final stockController = TextEditingController(text: (product.stock ?? 0).toString());
    final minStockController = TextEditingController(text: (product.minStock ?? 5).toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              decoration: const InputDecoration(
                labelText: 'Current Stock',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minStockController,
              decoration: const InputDecoration(
                labelText: 'Minimum Stock Level',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateStock(product.id, stockController.text, minStockController.text);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStock(String productId, String stock, String minStock) async {
    try {
      final stockValue = int.tryParse(stock) ?? 0;
      final minStockValue = int.tryParse(minStock) ?? 5;
      
      final docRef = FirebaseFirestore.instance
          .collection('products')
          .doc(productId);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        await docRef.update({
          'stock': stockValue,
          'minStock': minStockValue,
        });
      } else {
        await docRef.set({
          'stock': stockValue,
          'minStock': minStockValue,
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Management'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to manage inventory'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh Inventory',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('dealer', isEqualTo: _currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading inventory',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products in inventory',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products to start managing inventory',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs
              .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          // Calculate inventory statistics
          int totalProducts = products.length;
          int lowStockProducts = 0;
          int outOfStockProducts = 0;
          double totalValue = 0;

          for (var product in products) {
            final stock = product.stock ?? 0;
            final minStock = product.minStock ?? 5;
            final price = product.price;
            
            if (stock < minStock) lowStockProducts++;
            if (stock == 0) outOfStockProducts++;
            totalValue += stock * price;
          }

          return Column(
            children: [
              // Inventory Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Total Products',
                            '$totalProducts',
                            Icons.inventory,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryItem(
                            'Low Stock',
                            '$lowStockProducts',
                            Icons.warning,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Out of Stock',
                            '$outOfStockProducts',
                            Icons.remove_shopping_cart,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryItem(
                            'Total Value',
                            'RWF ${NumberFormat('#,###').format(totalValue)}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Products List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final stock = product.stock ?? 0;
                    final minStock = product.minStock ?? 5;
                    final isLowStock = stock < minStock;
                    final isOutOfStock = stock == 0;
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: (product.imageUrl.isNotEmpty && product.imageUrl.startsWith('http'))
                                ? Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                        ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  (loadingProgress.expectedTotalBytes ?? 1)
                                              : null,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                  ),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.description, maxLines: 2),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock 
                                        ? Colors.red.withOpacity(0.1)
                                        : isLowStock 
                                            ? Colors.orange.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isOutOfStock 
                                        ? 'Out of Stock'
                                        : isLowStock 
                                            ? 'Low Stock'
                                            : 'In Stock',
                                    style: TextStyle(
                                      color: isOutOfStock 
                                          ? Colors.red
                                          : isLowStock 
                                              ? Colors.orange
                                              : Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Stock: $stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RWF ${NumberFormat('#,###').format(product.price)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showStockUpdateDialog(product),
                          tooltip: 'Update Stock',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 