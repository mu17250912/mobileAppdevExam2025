import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/product_model.dart';
import 'add_edit_product_screen.dart';
import 'services/premium_service.dart';
import 'services/analytics_service.dart';
import 'premium_subscription_screen.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackScreenView('manage_products_screen');
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
          title: const Text('Manage Products'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to manage products'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
          FutureBuilder<bool>(
            future: PremiumService.canAddProduct(_currentUserId!),
            builder: (context, snapshot) {
              final canAdd = snapshot.data ?? false;
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: canAdd ? _addProduct : _showPremiumUpgrade,
                tooltip: canAdd ? 'Add Product' : 'Upgrade to Premium for unlimited products',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Premium Status Banner
          FutureBuilder<bool>(
            future: PremiumService.isPremiumUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              final isPremium = snapshot.data ?? false;
              
              if (!isPremium) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Free plan: Limited to 5 products. Upgrade for unlimited listings.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _navigateToPremium(),
                        child: Text(
                          'Upgrade',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
          
          // Product Count and Premium Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<int>(
                      future: PremiumService.getCurrentProductCount(_currentUserId!),
                      builder: (context, snapshot) {
                        final currentCount = snapshot.data ?? 0;
                        return Text(
                          'Products: $currentCount',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    FutureBuilder<bool>(
                      future: PremiumService.isPremiumUser(),
                      builder: (context, snapshot) {
                        final isPremium = snapshot.data ?? false;
                        if (!isPremium) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Limit: 5',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Unlimited',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<bool>(
                  future: PremiumService.isPremiumUser(),
                  builder: (context, snapshot) {
                    final isPremium = snapshot.data ?? false;
                    if (!isPremium) {
                      return Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Upgrade to Premium for unlimited product listings',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[600],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Premium active - Unlimited listings available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                          'Error loading products',
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
                          'No products yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first product to start selling',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addProduct,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!.docs
                    .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
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
                            Text(product.description ?? '', maxLines: 2),
                            const SizedBox(height: 4),
                            Text(
                              'RWF ${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editProduct(product);
                            } else if (value == 'delete') {
                              _deleteProduct(product);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addProduct() async {
    final canAdd = await PremiumService.canAddProduct(_currentUserId!);
    if (canAdd) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddEditProductScreen(),
        ),
      ).then((_) {
        // Refresh the screen when returning from add/edit product
        setState(() {});
      });
    } else {
      _showPremiumUpgrade();
    }
  }

  void _editProduct(Product product) {
    final productMap = product.toMap();
    productMap['id'] = product.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: productMap),
      ),
    ).then((_) {
      // Refresh the screen when returning from edit product
      setState(() {});
    });
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(product.id)
                    .delete();
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted successfully')),
                  );
                  // Refresh the screen
                  setState(() {});
                }
              } catch (error) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting product: $error')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPremiumUpgrade() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'You have reached the limit of 5 products on the free plan. '
          'Upgrade to Premium for unlimited product listings and more features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPremium();
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _navigateToPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PremiumSubscriptionScreen(username: ''), // Removed username parameter
      ),
    ).then((_) {
      // Refresh the screen when returning from premium subscription
      setState(() {});
    });
  }
} 