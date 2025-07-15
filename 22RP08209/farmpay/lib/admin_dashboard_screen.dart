import 'package:flutter/material.dart';
import 'order_approval_screen.dart';
import 'main.dart';
import 'products_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  late TabController _tabController;
  String userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Fetch orders, products, and users from Firestore
      final ordersSnap = await FirebaseFirestore.instance.collection('orders').orderBy('created_at', descending: true).get();
      final productsSnap = await FirebaseFirestore.instance.collection('products').get();
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> ordersList = ordersSnap.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      final List<Map<String, dynamic>> productsList = productsSnap.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      final List<Map<String, dynamic>> usersList = usersSnap.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      setState(() {
        orders = ordersList;
        products = productsList;
        users = usersList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard data: $e')),
      );
    }
  }

  void _approveOrder(int orderId) async {
    // TODO: Update order status in Firestore
    await _loadDashboardData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order approved!')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Users'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildUsersTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    'Approve Orders',
                    Icons.approval,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderApprovalScreen(),
                        ),
                      ).then((_) => _loadDashboardData());
                    },
                  ),
                  _buildActionCard(
                    'Send Notification',
                    Icons.notifications,
                    Colors.orange,
                    () => _showNotificationDialog(),
                  ),
                  _buildActionCard(
                    'View Products',
                    Icons.inventory,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    'View Reports',
                    Icons.analytics,
                    Colors.purple,
                    () {
                      _tabController.animateTo(2);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Pending Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...orders.where((order) => order['status'] == 'pending').map((order) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.pending, color: Colors.white),
                  ),
                  title: Text('Order #${order['id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User: ${order['userId'] ?? 'Unknown'}'),
                      Text('Total: RWF ${(order['total'] ?? 0).toStringAsFixed(0)}'),
                      Text('Items: ${(order['items'] as List).map((item) => '${item['name']} x${item['quantity']}').join(', ')}'),
                      Text('Placed: ${order['created_at']?.toString().split('T').first ?? ''}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () => _updateOrderStatus(order['id'], 'approved', order['userId']),
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () => _updateOrderStatus(order['id'], 'rejected', order['userId']),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 32),
              const Text(
                'Recent Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...orders.take(5).map((order) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(order['status']),
                        child: Icon(
                          _getStatusIcon(order['status']),
                          color: Colors.white,
                        ),
                      ),
                      title: Text('Order #${order['id']}'),
                      subtitle: Text(
                        '${order['user_name'] ?? 'Unknown'} - RWF ${(order['total_amount'] ?? 0).toStringAsFixed(0)}',
                      ),
                      trailing: Chip(
                        label: Text(
                          order['status'] ?? 'pending',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getStatusColor(order['status']),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        // Floating action button for adding products
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: _showAddProductDialog,
            icon: Icon(Icons.add),
            label: Text('Add Product'),
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    final filteredUsers = users.where((user) {
      final query = userSearchQuery.toLowerCase();
      return user['name'].toLowerCase().contains(query) || user['phone'].toLowerCase().contains(query);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Users: ${users.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.admin_panel_settings),
                    label: Text('Add Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showAddAdminDialog(),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name or phone',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          userSearchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // User table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Created At')),
              ],
              rows: filteredUsers.map((user) => DataRow(cells: [
                DataCell(Text(user['name'] ?? 'Unknown')),
                DataCell(Text(user['phone'] ?? '')),
                DataCell(Text(user['role'] ?? '')),
                DataCell(Text(user['created_at']?.toString().split('T').first ?? '')),
              ])).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    final totalRevenue = orders.fold<double>(0.0, (sum, order) => sum + (order['total_amount'] ?? 0.0));
    final totalOrders = orders.length;
    final approvedOrders = orders.where((o) => o['status'] == 'approved').length;
    final pendingOrders = orders.where((o) => o['status'] == 'pending').length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Total Users', users.length.toString(), Icons.people, Colors.blue),
                  _buildStatCard('Total Orders', totalOrders.toString(), Icons.shopping_cart, Colors.green),
                  _buildStatCard('Approved Orders', approvedOrders.toString(), Icons.check_circle, Colors.teal),
                  _buildStatCard('Pending Orders', pendingOrders.toString(), Icons.pending, Colors.orange),
                  _buildStatCard('Revenue', 'RWF ${totalRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.purple),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...orders.take(10).map((order) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(order['status']),
                    child: Icon(_getStatusIcon(order['status']), color: Colors.white),
                  ),
                  title: Text('Order #${order['id']}'),
                  subtitle: Text('${order['user_name'] ?? 'Unknown'} - RWF ${(order['total_amount'] ?? 0).toStringAsFixed(0)}'),
                  trailing: Chip(
                    label: Text(order['status'] ?? 'pending', style: const TextStyle(color: Colors.white)),
                    backgroundColor: _getStatusColor(order['status']),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.approval;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_cart;
    }
  }

  void _showNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                // TODO: Add notification in Firestore
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showRegisterUserDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'user';
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Register New User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Full Name'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password'),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) => setState(() => role = val ?? 'user'),
                      decoration: InputDecoration(labelText: 'Role'),
                    ),
                    if (errorText != null) ...[
                      SizedBox(height: 12),
                      Text(errorText!, style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() { isLoading = true; errorText = null; });
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          final password = passwordController.text;
                          if (name.isEmpty || phone.isEmpty || password.isEmpty) {
                            setState(() { isLoading = false; errorText = 'All fields are required.'; });
                            return;
                          }
                          if (password.length < 6) {
                            setState(() { isLoading = false; errorText = 'Password must be at least 6 characters.'; });
                            return;
                          }
                          try {
                            final email = '$phone@farmpay.com';
                            final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                              'name': name,
                              'phone': phone,
                              'role': role,
                              'premium_status': role == 'admin' ? 'approved' : 'none',
                              'created_at': DateTime.now().toIso8601String(),
                            });
                            setState(() { isLoading = false; });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('User registered successfully!'), backgroundColor: Colors.green),
                            );
                            _loadDashboardData();
                          } on FirebaseAuthException catch (e) {
                            setState(() { isLoading = false; errorText = e.message ?? 'Registration failed.'; });
                          } catch (e) {
                            setState(() { isLoading = false; errorText = 'Registration failed: $e'; });
                          }
                        },
                  child: isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Register'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddAdminDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Admin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Full Name'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password'),
                    ),
                    if (errorText != null) ...[
                      SizedBox(height: 12),
                      Text(errorText!, style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() { isLoading = true; errorText = null; });
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          final password = passwordController.text;
                          if (name.isEmpty || phone.isEmpty || password.isEmpty) {
                            setState(() { isLoading = false; errorText = 'All fields are required.'; });
                            return;
                          }
                          if (password.length < 6) {
                            setState(() { isLoading = false; errorText = 'Password must be at least 6 characters.'; });
                            return;
                          }
                          try {
                            final email = '$phone@farmpay.com';
                            final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                              'name': name,
                              'phone': phone,
                              'role': 'admin',
                              'premium_status': 'approved',
                              'created_at': DateTime.now().toIso8601String(),
                            });
                            setState(() { isLoading = false; });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Admin added successfully!'), backgroundColor: Colors.green),
                            );
                            _loadDashboardData();
                          } on FirebaseAuthException catch (e) {
                            setState(() { isLoading = false; errorText = e.message ?? 'Registration failed.'; });
                          } catch (e) {
                            setState(() { isLoading = false; errorText = 'Registration failed: $e'; });
                          }
                        },
                  child: isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Add Admin'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    String selectedCategory = 'Nitrogen';
    bool isLoading = false;
    String? errorText;
    final categories = [
      'Nitrogen', 'Phosphate', 'Potassium', 'Balanced', 'Organic', 'Micronutrients'
    ];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Product Name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val ?? 'Nitrogen'),
                      decoration: InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Price (RWF)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrlController,
                      decoration: InputDecoration(labelText: 'Image URL (optional)'),
                    ),
                    if (errorText != null) ...[
                      SizedBox(height: 12),
                      Text(errorText!, style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() { isLoading = true; errorText = null; });
                          final name = nameController.text.trim();
                          final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                          final description = descriptionController.text.trim();
                          final imageUrl = imageUrlController.text.trim();
                          if (name.isEmpty || price <= 0 || description.isEmpty) {
                            setState(() { isLoading = false; errorText = 'All fields except image are required and price must be > 0.'; });
                            return;
                          }
                          try {
                            await FirebaseFirestore.instance.collection('products').add({
                              'name': name,
                              'category': selectedCategory,
                              'price': price,
                              'description': description,
                              if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
                            });
                            setState(() { isLoading = false; });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Product added!'), backgroundColor: Colors.green),
                            );
                            _loadDashboardData();
                          } catch (e) {
                            setState(() { isLoading = false; errorText = 'Error: $e'; });
                          }
                        },
                  child: isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': status});
      // Notify user
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'order_status',
        'orderId': orderId,
        'userId': userId,
        'message': status == 'approved' ? 'Your order has been approved!' : 'Your order has been rejected.',
        'status': 'unread',
        'created_at': DateTime.now().toIso8601String(),
      });
      _loadDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order $status!'), backgroundColor: status == 'approved' ? Colors.green : Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }
} 