import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for StreamBuilder
import 'product_listing_screen.dart';
import 'my_products_screen.dart';
import 'order_management_screen.dart';
import 'profile_screen.dart';
import 'cart_provider.dart';
import 'theme/app_colors.dart';
import 'user_provider.dart';
import 'admin_analytics_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF145A32)), // dark green
        title: const Text('Admin Panel', style: TextStyle(color: Color(0xFF145A32), fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF145A32), // dark green
          unselectedLabelColor: Colors.black87,
          indicatorColor: const Color(0xFF2E8B57), // Sea Green
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AdminUsersTab(),
          _AdminProductsTab(),
          _AdminOrdersTab(),
          AdminAnalyticsScreen(),
        ],
      ),
    );
  }
}

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final userId = docs[i].id;
            return ListTile(
              title: Text(data['email'] ?? ''),
              subtitle: Text('Role: ${data['userType'] ?? 'Unknown'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: data['userType'] ?? 'Farmer',
                    items: const [
                      DropdownMenuItem(value: 'Farmer', child: Text('Farmer')),
                      DropdownMenuItem(value: 'Buyer', child: Text('Buyer')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        await FirebaseFirestore.instance.collection('users').doc(userId).update({'userType': val});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Role updated to $val')),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete User'),
                          content: const Text('Are you sure you want to delete this user?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User deleted')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminProductsTab extends StatelessWidget {
  const _AdminProductsTab();

  Future<void> _editProduct(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name'] ?? '');
    final quantityController = TextEditingController(text: data['quantity']?.toString() ?? '');
    final priceController = TextEditingController(text: data['price']?.toString() ?? '');
    String? unit = data['unit'];
    final units = ['kg', 'l', 'pcs', 'g', 'ml'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: unit,
                      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => unit = val,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price per Unit (RWF)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({
                'name': nameController.text.trim(),
                'quantity': double.tryParse(quantityController.text.trim()) ?? 0,
                'unit': unit,
                'price': double.tryParse(priceController.text.trim()) ?? 0,
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found.'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? ''),
              subtitle: Text('Price: RWF ${data['price']} | Qty: ${data['quantity']} ${data['unit'] ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editProduct(context, docs[i]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Product'),
                          content: const Text('Are you sure you want to delete this product?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance.collection('products').doc(docs[i].id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product deleted')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminOrdersTab extends StatelessWidget {
  const _AdminOrdersTab();

  Future<void> _updateOrderStatus(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final currentStatus = data['status'] ?? 'pending';
    final statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
    String selectedStatus = currentStatus;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: DropdownButtonFormField<String>(
          value: selectedStatus,
          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
          onChanged: (val) {
            if (val != null) selectedStatus = val;
          },
          decoration: const InputDecoration(labelText: 'Order Status'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({'status': selectedStatus});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text('Order ID: ${data['id']}'),
              subtitle: Text('Customer: ${data['customerName']} | Status: ${data['status']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _updateOrderStatus(context, docs[i]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Order'),
                          content: const Text('Are you sure you want to delete this order?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance.collection('orders').doc(docs[i].id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order deleted')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userType = userProvider.userType;
    if (userProvider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userType == null) {
      return const Scaffold(body: Center(child: Text('User type not found.')));
    }

    // Build tabs/screens based on userType
    List<Widget> screens = [];
    List<BottomNavigationBarItem> items = [];

    // Products tab (everyone)
    screens.add(const ProductListingScreen());
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Products'));

    // My Products (Farmer, Admin)
    if (userType == 'Farmer' || userType == 'Admin') {
      screens.add(const MyProductsScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'My Products'));
    }

    // Orders (everyone)
    screens.add(const OrderManagementScreen());
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'));

    // Admin Panel (Admin only)
    if (userType == 'Admin') {
      screens.add(const AdminPanelScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
    }

    // Profile (everyone)
    screens.add(const ProfileScreen());
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriConnect'),
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
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: items,
      ),
    );
  }
} 