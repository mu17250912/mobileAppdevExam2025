import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import './seller_profile.dart';
import 'package:intl/intl.dart';
import '../seller_premium_page.dart';
import 'dart:async';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({Key? key}) : super(key: key);
  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<Map<String, dynamic>?> getBuyerInfo(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[900]!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Orders'),
        backgroundColor: themeColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading orders'));
          }
          final orders = snapshot.data?.docs ?? [];
          final sellerOrders = orders.where((order) {
            final items = (order['items'] as List?) ?? [];
            return items.any((item) => item['sellerId'] == sellerId);
          }).toList();
          if (sellerOrders.isEmpty) {
            return const Center(child: Text('No orders for your products yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sellerOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = sellerOrders[index];
              final data = order.data() as Map<String, dynamic>;
              final orderId = order.id;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final status = data['status'] ?? 'pending';
              final paymentStatus = data['paymentStatus'] ?? 'pending';
              final userId = data['userId'] ?? '';
              final items = (data['items'] as List?)?.where((item) => item['sellerId'] == sellerId).toList() ?? [];
              final total = items.fold(0.0, (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)));
              final commissions = (data['commissions'] as List?) ?? [];
              final sellerCommission = commissions
                  .where((c) => c['sellerId'] == sellerId)
                  .map((c) => c['amount'])
                  .fold(0.0, (sum, amount) => sum + (amount ?? 0.0));
              return FutureBuilder<Map<String, dynamic>?>(
                future: getBuyerInfo(userId),
                builder: (context, buyerSnapshot) {
                  final buyer = buyerSnapshot.data;
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order: ${orderId.substring(0, 8)}', style: TextStyle(fontWeight: FontWeight.bold, color: themeColor)),
                              Text(timestamp != null ? DateFormat('yMMMd').add_jm().format(timestamp) : '', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Buyer: ${buyer?['fullName'] ?? 'Unknown'} (${buyer?['email'] ?? ''})'),
                          const SizedBox(height: 8),
                          const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('${item['name']} x${item['quantity']} (FRW ${item['price']?.toStringAsFixed(2) ?? '0.00'})'),
                          )),
                          const SizedBox(height: 8),
                          Text('Total: FRW ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (sellerCommission > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Commission deducted: FRW ${sellerCommission.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text(status.toUpperCase()),
                                backgroundColor: status == 'confirmed' ? Colors.green[100] : status == 'cancelled' ? Colors.red[100] : Colors.yellow[100],
                                labelStyle: TextStyle(
                                  color: status == 'confirmed' ? Colors.green[800] : status == 'cancelled' ? Colors.red[800] : Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (paymentStatus == 'paid' && status == 'pending')
                                ElevatedButton(
                                  onPressed: () => updateOrderStatus(orderId, 'confirmed'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                                  child: const Text('Confirm Payment'),
                                ),
                              if (status == 'confirmed')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text('Payment Confirmed', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                                ),
                              const Spacer(),
                              if (status == 'pending') ...[
                                ElevatedButton(
                                  onPressed: () => updateOrderStatus(orderId, 'cancelled'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                                  child: const Text('Cancel'),
                                ),
                              ]
                            ],
                          ),
                          if (paymentStatus == 'paid')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('Payment received via: ${data['paymentMethod'] ?? ''} (${data['paymentNumber'] ?? ''})', style: TextStyle(color: Colors.blue[800])),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PremiumCountdown extends StatefulWidget {
  final DateTime premiumUntil;
  const PremiumCountdown({Key? key, required this.premiumUntil}) : super(key: key);

  @override
  State<PremiumCountdown> createState() => _PremiumCountdownState();
}

class _PremiumCountdownState extends State<PremiumCountdown> {
  late Duration timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    setState(() {
      timeLeft = widget.premiumUntil.difference(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (timeLeft.isNegative) {
      return Text(
        'Premium expired!',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }
    final days = timeLeft.inDays;
    final hours = timeLeft.inHours % 24;
    final minutes = timeLeft.inMinutes % 60;
    final isExpiringSoon = timeLeft.inDays < 3;
    return Text(
      'Expires in:  [1m${days}d ${hours}h ${minutes}m [0m',
      style: TextStyle(
        color: isExpiringSoon ? Colors.red : Colors.green[800],
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final List<String> categories = ['All', 'Phone', 'Laptop', 'Tablet', 'Accessories', 'Other'];
  String selectedCategory = 'All';
  final TextEditingController searchController = TextEditingController();

  // Notification bell state
  int notificationCount = 0;
  List<Map<String, dynamic>> newOrders = [];
  bool notificationsRead = false;
  String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isPremium = false;
  DateTime? premiumUntil;

  @override
  void initState() {
    super.initState();
    _listenToNewOrders();
    _fetchPremiumStatus();
  }

  Future<void> _fetchPremiumStatus() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
    setState(() {
      isPremium = userDoc['isPremium'] == true;
      if (userDoc.data() != null && userDoc.data()!.containsKey('premiumUntil')) {
        premiumUntil = (userDoc['premiumUntil'] as Timestamp?)?.toDate();
      }
    });
  }

  void _listenToNewOrders() {
    FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final orders = snapshot.docs.where((order) {
        final data = order.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        final items = (data['items'] as List?) ?? [];
        return status == 'pending' && items.any((item) => item['sellerId'] == sellerId);
      }).toList();
      setState(() {
        newOrders = orders.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'docId': doc.id, // Add Firestore document ID for reliable updates
          };
        }).toList();
        notificationCount = notificationsRead ? 0 : newOrders.length;
      });
    });
  }

  void _openNotificationsPage() {
    setState(() {
      notificationsRead = true;
      notificationCount = 0;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellerNotificationsPage(orders: newOrders)),
    );
  }

  Future<int> getTotalProducts(String sellerId) async {
    print('DEBUG: getTotalProducts called with sellerId: $sellerId');
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .get();
    return snapshot.size;
  }

  Future<int> getTotalOrders(String sellerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('sellerIds', arrayContains: sellerId)
        .get();
    return snapshot.size;
  }

  Future<double> getTotalSales(String sellerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('sellerIds', arrayContains: sellerId)
        .where('paymentStatus', isEqualTo: 'paid')
        .where('status', isEqualTo: 'confirmed')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final items = (data['items'] as List?) ?? [];
      final sellerItems = items.where((item) => item['sellerId'] == sellerId).toList();
      total += sellerItems.fold(0.0, (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)));
    }
    return total;
  }

  Future<double> getTotalCommissions(String sellerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerIds', arrayContains: sellerId)
          .where('paymentStatus', isEqualTo: 'paid')
          .where('status', isEqualTo: 'confirmed')
          .get();

      double totalCommission = 0;
      for (var doc in snapshot.docs) {
        final commissions = (doc['commissions'] as List?) ?? [];
        for (final c in commissions) {
          if (c is Map && c['sellerId'] == sellerId && c['amount'] is num) {
            totalCommission += c['amount'];
          }
        }
      }
      return totalCommission;
    } catch (e, stack) {
      debugPrint('Error in getTotalCommissions: $e\n$stack');
      return 0.0;
    }
  }

  void showProductDialog({DocumentSnapshot? product}) {
    final data = product?.data() as Map<String, dynamic>?;
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final stockController = TextEditingController(text: (data != null && data.containsKey('stock')) ? data['stock']?.toString() ?? '' : '');
    final specsController = TextEditingController(text: (data != null && data.containsKey('specs')) ? data['specs'] ?? '' : '');
    final List<String> categories = ['All', 'Phone', 'Laptop', 'Tablet', 'Accessories', 'Other'];
    String selectedCategory = product?['category'] ?? categories.first;
    final descriptionController = TextEditingController(text: product?['description'] ?? '');
    final imageUrlController = TextEditingController(text: product?['imageUrl'] ?? '');
    // Debug: Print current user UID
    final currentUser = FirebaseAuth.instance.currentUser;
    print('DEBUG: Current user UID: ${currentUser?.uid}');
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(product == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (imageUrlController.text.isNotEmpty)
                        ? Image.network(
                            imageUrlController.text,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(height: 100, width: 100, child: Center(child: CircularProgressIndicator()));
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                width: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 40),
                              );
                            },
                          )
                              : Container(
                                  height: 100,
                                  width: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.camera_alt, size: 40),
                                ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                      onChanged: (_) => setStateDialog(() {}),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: stockController,
                      decoration: const InputDecoration(labelText: 'Stock (Quantity)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: specsController,
                      decoration: const InputDecoration(labelText: 'Specifications'),
                      maxLines: 3,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        setStateDialog(() => selectedCategory = val!);
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
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
                    final sellerId = FirebaseAuth.instance.currentUser?.uid;
                    print('DEBUG: Using sellerId for product: $sellerId');
                    if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                    final finalImageUrl = imageUrlController.text.trim();
                    final stock = int.tryParse(stockController.text.trim()) ?? 0;
                    final specs = specsController.text.trim();
                    if (product == null) {
                      // Add
                      await FirebaseFirestore.instance.collection('products').add({
                        'name': nameController.text.trim(),
                        'price': double.tryParse(priceController.text.trim()) ?? 0,
                        'stock': stock,
                        'specs': specs,
                        'category': selectedCategory,
                        'description': descriptionController.text.trim(),
                        'sellerId': sellerId,
                        'createdAt': Timestamp.now(),
                        'imageUrl': finalImageUrl,
                      });
                    } else {
                      // Edit
                      await FirebaseFirestore.instance.collection('products').doc(product.id).update({
                        'name': nameController.text.trim(),
                        'price': double.tryParse(priceController.text.trim()) ?? 0,
                        'stock': stock,
                        'specs': specs,
                        'category': selectedCategory,
                        'description': descriptionController.text.trim(),
                        'imageUrl': finalImageUrl,
                      });
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(product == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[900]!;
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Seller Dashboard"),
        backgroundColor: themeColor,
        actions: [
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                tooltip: 'Notifications',
                onPressed: _openNotificationsPage,
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: themeColor),
              child: Row(
                children: [
                  Icon(Icons.account_circle, color: Colors.white, size: 48),
                  const SizedBox(width: 12),
                  Text('Seller', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context), // Already on home
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('My Products'),
              onTap: () {
                Navigator.pop(context);
                // Optionally scroll to products section or implement navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerOrdersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerProfilePage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProductDialog(),
        backgroundColor: themeColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (isPremium)
                    Chip(
                      label: const Text('Premium Seller', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.amber[700],
                      avatar: const Icon(Icons.star, color: Colors.white),
                    ),
                  if (!isPremium)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.star, color: Colors.amber),
                      label: const Text('Go Premium'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SellerPremiumPage()),
                        );
                        _fetchPremiumStatus(); // Refresh after returning
                      },
                    ),
                  if (isPremium && premiumUntil != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                          Text('Valid until:  [1m${DateFormat('yMMMd').format(premiumUntil!)} [0m', style: TextStyle(color: Colors.amber[900])),
                          PremiumCountdown(premiumUntil: premiumUntil!),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
              const SizedBox(height: 16),
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Products',
                      future: getTotalProducts(sellerId),
                      icon: Icons.inventory_2,
                      color: Colors.orange[700]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Sales',
                      future: getTotalSales(sellerId),
                      icon: Icons.attach_money,
                      color: Colors.green[700]!,
                      isMoney: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Orders',
                      future: getTotalOrders(sellerId),
                      icon: Icons.shopping_bag,
                      color: Colors.purple[700]!,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Total Commission',
                    future: getTotalCommissions(sellerId),
                    icon: Icons.percent,
                    color: Colors.red[700]!,
                    isMoney: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Your Products',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor),
              ),
            const SizedBox(height: 12),
            // Search bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Category chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (_) => setState(() => selectedCategory = cat),
                    selectedColor: themeColor.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: selectedCategory == cat ? themeColor : Colors.black,
                      fontWeight: selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                )).toList(),
              ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('sellerId', isEqualTo: sellerId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                final allProducts = snapshot.data?.docs ?? [];
                final filteredProducts = allProducts.where((product) {
                  final data = product.data() as Map<String, dynamic>;
                  final matchesCategory = selectedCategory == 'All' || data['category'] == selectedCategory;
                  final matchesSearch = searchController.text.isEmpty ||
                    (data['name']?.toLowerCase().contains(searchController.text.toLowerCase()) ?? false);
                  return matchesCategory && matchesSearch;
                }).toList();
                if (filteredProducts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No products yet. Tap + to add.')),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                    final product = filteredProducts[i];
                    final data = product.data() as Map<String, dynamic>;
                    final imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : '';
                    final stock = data.containsKey('stock') ? data['stock'] : 'N/A';
                    final specs = data.containsKey('specs') ? data['specs'] : '';
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(child: CircularProgressIndicator(strokeWidth: 2));
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.broken_image, color: Colors.grey, size: 40);
                                    },
                                  ),
                                )
                              : Icon(Icons.devices_other, color: themeColor, size: 40),
                        ),
                        title: Text(data['name'] ?? ''),
                          subtitle: Text(
                          'Category: ${data['category'] ?? ''}\n'
                          'Price: FRW ${data['price']?.toStringAsFixed(2) ?? '0.00'}\n'
                          'Stock: ${stock}\n'
                          'Specs: ${specs}\n'
                          '${(data.containsKey('description') && data['description'] != null && data['description'].toString().isNotEmpty) ? 'Description: ${data['description']}' : ''}'
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => showProductDialog(product: product),
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
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await deleteProduct(product.id);
                                    setState(() {}); // Refresh UI after delete
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Future future;
  final IconData icon;
  final Color color;
  final bool isMoney;

  const _StatCard({
    required this.title,
    required this.future,
    required this.icon,
    required this.color,
    this.isMoney = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 16),
            FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(strokeWidth: 2);
                }
                // If error, show 0 instead of 'Error'
                if (snapshot.hasError) {
                  return Text(
                    isMoney ? ' 0.00' : '0',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                  );
                }
                final value = snapshot.data ?? 0.0;
                double displayValue = 0.0;
                if (value is num) {
                  displayValue = value.toDouble();
                } else if (value is String) {
                  displayValue = double.tryParse(value) ?? 0.0;
                }
                // Defensive: if still not a number, fallback to 0
                if (displayValue.isNaN || displayValue.isInfinite) displayValue = 0.0;
                return Text(
                  isMoney ? ' ${displayValue.toStringAsFixed(2)}' : displayValue.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// --- Seller Notifications Page ---
class SellerNotificationsPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const SellerNotificationsPage({Key? key, required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[900]!;
    final sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Only show paid orders
    final paidOrders = orders.where((order) => order['paymentStatus'] == 'paid').toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paid Order Notifications'),
        backgroundColor: themeColor,
      ),
      body: paidOrders.isEmpty
          ? const Center(child: Text('No paid orders to confirm.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: paidOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = paidOrders[index];
                final timestamp = (order['timestamp'] is Timestamp)
                    ? (order['timestamp'] as Timestamp).toDate()
                    : null;
                final userId = order['userId'] ?? '';
                final items = (order['items'] as List?) ?? [];
                final sellerItems = items.where((item) => item['sellerId'] == sellerId).toList();
                final total = sellerItems.fold(0.0, (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)));
                final status = order['status'] ?? 'pending';
                final paymentMethod = order['paymentMethod'] ?? 'N/A';
                final paymentNumber = order['paymentNumber'] ?? '';
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(Icons.payments, color: themeColor),
                    title: Text('Order Paid'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: FRW ${total.toStringAsFixed(2)}'),
                        Text('Items: ${sellerItems.length}'),
                        if (timestamp != null)
                          Text('Paid on: ${DateFormat('yMMMd').add_jm().format(timestamp)}'),
                        Text('Payment Method: $paymentMethod'),
                        if (paymentNumber.isNotEmpty)
                          Text('Number/Email: $paymentNumber'),
                        Text('Order Status: $status'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: status == 'pending'
                        ? ElevatedButton(
                            onPressed: () async {
                              // Confirm payment
                              final orderId = order['orderId'] ?? '';
                              // If orderId is not present in data, you may need to pass it from the parent
                              // or refactor to use the Firestore doc ID.
                              // For now, let's assume you have the doc ID in the order map as 'docId'.
                              final docId = order['docId'] ?? '';
                              if (docId.isNotEmpty) {
                                await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': 'confirmed'});
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment confirmed!')));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                            child: const Text('Confirm Payment'),
                          )
                        : Text('Confirmed', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Order Details'),
                          content: SizedBox(
                            width: 320,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Order Status: $status'),
                                  Text('Payment Method: $paymentMethod'),
                                  if (paymentNumber.isNotEmpty)
                                    Text('Number/Email: $paymentNumber'),
                                  Text('Total: FRW ${total.toStringAsFixed(2)}'),
                                  if (timestamp != null)
                                    Text('Paid on: ${DateFormat('yMMMd').add_jm().format(timestamp)}'),
                                  const SizedBox(height: 8),
                                  const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...sellerItems.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text('${item['name']} x${item['quantity']} (FRW ${item['price']?.toStringAsFixed(2) ?? '0.00'})'),
                                  )),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
      ),
    );
  }
}
