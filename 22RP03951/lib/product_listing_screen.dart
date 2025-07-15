import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'add_product_screen.dart';
import 'cart_provider.dart';
import 'cart_item.dart';
import 'theme/app_colors.dart';
import 'user_provider.dart';
import 'analytics_service.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({Key? key}) : super(key: key);

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final Map<String, double> _quantities = {};

  void _addToCart(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final productId = doc.id;
    final quantity = _quantities[productId] ?? 1.0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: productId,
      productName: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: quantity,
      unit: data['unit'] ?? '',
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
    );

    context.read<CartProvider>().addItem(cartItem);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['name']} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            // Navigate to cart screen
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }

  void _showAddToCartDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final productId = doc.id;
    final quantityController = TextEditingController(
      text: (_quantities[productId] ?? 1.0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${data['name']} to Cart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Price: RWF ${data['price']} per ${data['unit']}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity (${data['unit']})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _quantities[productId] = double.tryParse(value) ?? 0;
              },
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
              Navigator.pop(context);
              _addToCart(doc);
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userType = userProvider.userType;
    final userId = userProvider.userData?['uid'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Listing'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
              if (context.watch<CartProvider>().itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${context.watch<CartProvider>().itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error:  ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final isOwnProduct = data['farmerId'] == userId;
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text('Price: RWF ${data['price']} | Qty: ${data['quantity']} ${data['unit'] ?? ''}'),
                onTap: () {
                  // Track product view analytics
                  AnalyticsService.trackProductView(docs[i].id, data['name'] ?? '');
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userType == 'Admin' || (userType == 'Farmer' && isOwnProduct)) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {/* TODO: implement edit for admin/farmer */},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {/* TODO: implement delete for admin/farmer */},
                      ),
                    ] else if (userType == 'Farmer' && isOwnProduct) ...[
                      // Farmer cannot order their own product
                    ] else ...[
                      // Buyer or Farmer (not own product): can order
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          // Premium users get priority ordering
                          if (userProvider.isPremiumUser()) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                                  onPressed: () => _addToCart(docs[i]),
                                ),
                              ],
                            );
                          } else {
                            return IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                              onPressed: () => _addToCart(docs[i]),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
      ),
    );
  }
} 