import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/product_card.dart';
import '../product/add_product_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedIndex = 0;
  bool _isPremium = false;
  double _monthlyRevenue = 0.0;
  int _totalSales = 0;
  int _pendingOrders = 0;
  int _lowStockItems = 0;
  int _unreadReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardStats();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _isPremium = userDoc.data()?['isPremium'] ?? false;
            _monthlyRevenue = (userDoc.data()?['monthlyRevenue'] ?? 0.0).toDouble();
            _totalSales = userDoc.data()?['totalSales'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load pending orders
        final ordersQuery = await FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pending')
            .get();
        
        // Load low stock products
        final productsQuery = await FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: user.uid)
            .where('stock', isLessThanOrEqualTo: 5)
            .get();
        
        // Load unread reviews
        final reviewsQuery = await FirebaseFirestore.instance
            .collection('reviews')
            .where('sellerId', isEqualTo: user.uid)
            .where('isRead', isEqualTo: false)
            .get();

        setState(() {
          _pendingOrders = ordersQuery.docs.length;
          _lowStockItems = productsQuery.docs.length;
          _unreadReviews = reviewsQuery.docs.length;
        });
      }
    } catch (e) {
      print('Error loading dashboard stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isPremium ? Icons.star : Icons.star_border),
            onPressed: () => _showPremiumDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Revenue'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildProductsTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildAnalyticsTab();
      case 4:
        return _buildRevenueTab();
      case 5:
        return _buildProfileTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Status Card
          Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPremium 
                    ? [Colors.amber, Colors.orange]
                    : [Colors.grey.shade300, Colors.grey.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPremium ? Icons.star : Icons.star_border,
                    color: _isPremium ? Colors.white : Colors.grey.shade600,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPremium ? 'Premium Seller' : 'Free Plan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isPremium ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          _isPremium 
                            ? 'Unlimited listings & priority support'
                            : 'Upgrade for unlimited listings',
                          style: TextStyle(
                            color: _isPremium ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isPremium)
                    ElevatedButton(
                      onPressed: () => _showPremiumDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Upgrade'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Key Metrics
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Monthly Revenue',
                  '\$${_monthlyRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Sales',
                  _totalSales.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending Orders',
                  _pendingOrders.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Low Stock',
                  _lowStockItems.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Alerts Section
          if (_pendingOrders > 0 || _lowStockItems > 0 || _unreadReviews > 0)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Action Required',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_pendingOrders > 0)
                      _buildAlertRow('$_pendingOrders pending orders', Icons.shopping_bag, () => setState(() => _selectedIndex = 2)),
                    if (_lowStockItems > 0)
                      _buildAlertRow('$_lowStockItems items low on stock', Icons.inventory, () => setState(() => _selectedIndex = 1)),
                    if (_unreadReviews > 0)
                      _buildAlertRow('$_unreadReviews unread reviews', Icons.rate_review, () => _showReviews()),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Add Product',
                  Icons.add_circle,
                  Colors.deepPurple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddProductScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'View Orders',
                  Icons.shopping_bag,
                  Colors.orange,
                  () => setState(() => _selectedIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Analytics',
                  Icons.analytics,
                  Colors.blue,
                  () => setState(() => _selectedIndex = 3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Reviews',
                  Icons.rate_review,
                  Colors.green,
                  () => _showReviews(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                  fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data?.docs ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Products (${products.length})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddProductScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No products yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Add your first product to start selling',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade100,
                              child: Icon(Icons.inventory, color: Colors.deepPurple),
                            ),
                            title: Text(product['name'] ?? 'Unknown Product'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('\$${(product['price'] ?? 0.0).toStringAsFixed(2)}'),
                                Row(
                                  children: [
                                    Icon(
                                      product['stock'] <= 5 ? Icons.warning : Icons.check_circle,
                                      size: 16,
                                      color: product['stock'] <= 5 ? Colors.orange : Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('Stock: ${product['stock'] ?? 0}'),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
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
                              onSelected: (value) {
                                if (value == 'edit') {
                                  // Navigate to edit product
                                } else if (value == 'delete') {
                                  _showDeleteConfirmation(product['id']);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Orders (${orders.length})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: 'all',
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Orders')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                      DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                    ],
                    onChanged: (value) {
                      // Filter orders
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Orders will appear here when customers buy your products',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
                              child: Icon(
                                _getStatusIcon(order['status']),
                                color: _getStatusColor(order['status']),
                              ),
                            ),
                            title: Text('Order #${order['orderId'] ?? 'Unknown'}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customer: ${order['customerName'] ?? 'Unknown'}'),
                                Text('Total: \$${(order['total'] ?? 0.0).toStringAsFixed(2)}'),
                                Text('Status: ${order['status'] ?? 'Unknown'}'),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 8),
                                      Text('View Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'ship',
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_shipping),
                                      SizedBox(width: 8),
                                      Text('Mark as Shipped'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'view') {
                                  _showOrderDetails(order);
                                } else if (value == 'ship') {
                                  _updateOrderStatus(order['id'], 'shipped');
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.shopping_bag;
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order['orderId']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order['customerName']}'),
            Text('Email: ${order['customerEmail']}'),
            Text('Phone: ${order['customerPhone']}'),
            const SizedBox(height: 16),
            Text('Shipping Address:'),
            Text(order['shippingAddress'] ?? 'No address provided'),
            const SizedBox(height: 16),
            Text('Items:'),
            // Add order items here
            const SizedBox(height: 16),
            Text('Total: \$${(order['total'] ?? 0.0).toStringAsFixed(2)}'),
            Text('Status: ${order['status']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (order['status'] == 'pending')
            ElevatedButton(
              onPressed: () {
                _updateOrderStatus(order['id'], 'shipped');
                Navigator.pop(context);
              },
              child: const Text('Mark as Shipped'),
            ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': status});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating order status')),
      );
    }
  }

  void _showDeleteConfirmation(String? productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete product logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Performance Metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow('Views', '1,234', Icons.visibility),
                  _buildMetricRow('Clicks', '567', Icons.touch_app),
                  _buildMetricRow('Conversions', '89', Icons.trending_up),
                  _buildMetricRow('Revenue', '\$${_monthlyRevenue.toStringAsFixed(2)}', Icons.attach_money),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Sales Analytics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard('Total Sales', _totalSales.toString(), Icons.shopping_cart, Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard('Avg. Order', '\$${(_monthlyRevenue / (_totalSales > 0 ? _totalSales : 1)).toStringAsFixed(2)}', Icons.analytics, Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard('Conversion Rate', '7.2%', Icons.trending_up, Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard('Return Rate', '2.1%', Icons.assignment_return, Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Customer Analytics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow('New Customers', '45', Icons.person_add),
                  _buildMetricRow('Repeat Customers', '23', Icons.people),
                  _buildMetricRow('Customer Satisfaction', '4.5/5', Icons.star),
                  _buildMetricRow('Response Time', '2.3 hours', Icons.schedule),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Top Products
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Performing Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTopProductRow('Nike Air Max', '156 views', '\$89.99'),
                  _buildTopProductRow('Adidas Ultraboost', '134 views', '\$129.99'),
                  _buildTopProductRow('Converse Chuck Taylor', '98 views', '\$59.99'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Inventory Analytics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inventory Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow('Total Products', '24', Icons.inventory),
                  _buildMetricRow('Low Stock Items', _lowStockItems.toString(), Icons.warning),
                  _buildMetricRow('Out of Stock', '3', Icons.remove_shopping_cart),
                  _buildMetricRow('Stock Value', '\$12,450', Icons.attach_money),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductRow(String name, String views, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(views, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue & Payments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Revenue Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Month',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRevenueMetric('Gross Sales', '\$${(_monthlyRevenue * 1.15).toStringAsFixed(2)}'),
                      ),
                      Expanded(
                        child: _buildRevenueMetric('Platform Fee', '\$${(_monthlyRevenue * 0.15).toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRevenueMetric('Net Revenue', '\$${_monthlyRevenue.toStringAsFixed(2)}', isTotal: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Payment Methods
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Methods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethod('PayPal', 'Connected', Icons.payment, Colors.blue),
                  _buildPaymentMethod('Stripe', 'Connected', Icons.credit_card, Colors.purple),
                  _buildPaymentMethod('Bank Transfer', 'Pending', Icons.account_balance, Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Withdrawal Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Withdrawals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _monthlyRevenue > 0 ? () => _showWithdrawalDialog() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Withdraw Funds'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Minimum withdrawal: \$50.00',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueMetric(String label, String amount, {bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.deepPurple : Colors.grey.shade700,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.deepPurple : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(String name, String status, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Connected' ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'Connected' ? Colors.green.shade700 : Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Account Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildProfileRow('Email', FirebaseAuth.instance.currentUser?.email ?? ''),
                  _buildProfileRow('Member Since', 'January 2024'),
                  _buildProfileRow('Status', _isPremium ? 'Premium' : 'Free'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Settings
          Card(
        child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Premium Features:'),
            const SizedBox(height: 8),
            _buildFeatureRow('✓ Unlimited product listings'),
            _buildFeatureRow('✓ Priority customer support'),
            _buildFeatureRow('✓ Advanced analytics'),
            _buildFeatureRow('✓ Featured product placement'),
            _buildFeatureRow('✓ Reduced transaction fees'),
            const SizedBox(height: 16),
            const Text(
              'Monthly Subscription: \$9.99',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              // Implement subscription logic
              setState(() {
                _isPremium = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium subscription activated!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(feature),
    );
  }

  void _showWithdrawalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available balance: \$${_monthlyRevenue.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Amount to withdraw',
                prefixText: '\$',
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request submitted!')),
              );
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange.shade700),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationRow('New Order', 'You have a new order from John Doe', Icons.shopping_bag, Colors.blue),
            _buildNotificationRow('Low Stock Alert', 'Product XYZ is running low on stock', Icons.warning, Colors.orange),
            _buildNotificationRow('New Review', 'You received a new review for your product', Icons.rate_review, Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(String title, String message, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(message, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviews() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unread Reviews'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReviewRow('Great product!', '★★★★★', Icons.star, Colors.yellow.shade700),
            _buildReviewRow('Good quality, but slow shipping.', '★★★★☆', Icons.star_half, Colors.orange.shade700),
            _buildReviewRow('Very disappointed with the product.', '★☆☆☆☆', Icons.star_border, Colors.red.shade700),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String comment, String rating, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(comment),
          ),
          Text(rating, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }
} 