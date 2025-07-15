import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './buyer_profile.dart';
import 'dart:async'; // Added for StreamSubscription
import 'package:intl/intl.dart';
import '../payment_demo_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:marquee/marquee.dart';

// Marquee text widget (move to top-level)
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double velocity; // pixels per second
  const _MarqueeText({required this.text, required this.style, this.velocity = 50.0});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _controller;
  double _textWidth = 0;
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  void _startMarquee() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final textRenderBox = context.findRenderObject() as RenderBox?;
    if (textRenderBox == null) return;
    _textWidth = textRenderBox.size.width;
    _containerWidth = context.size?.width ?? 200;
    if (_textWidth <= _containerWidth) return;
    final duration = Duration(milliseconds: ((_textWidth + _containerWidth) / widget.velocity * 1000).toInt());
    _controller = AnimationController(vsync: this, duration: duration)
      ..addListener(() {
        _scrollController.jumpTo(_controller.value * (_textWidth + _containerWidth));
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text(widget.text, style: widget.style),
        const SizedBox(width: 40),
        Text(widget.text, style: widget.style), // repeat for seamless loop
      ],
    );
  }
}

class BuyerDashboard extends StatefulWidget {
  BuyerDashboard({super.key});

  @override
  _BuyerDashboardState createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  final List<String> categories = ['All', 'Phone', 'Laptop', 'Tablet', 'Accessories', 'Other'];
  String selectedCategory = 'All';
  final TextEditingController searchController = TextEditingController();

  // Cart item count
  int cartCount = 0;
  StreamSubscription<DocumentSnapshot>? _cartSubscription;

  // Notification bell state
  int notificationCount = 0;
  List<Map<String, dynamic>> recentOrders = [];
  bool notificationsRead = false;

  bool isAdFree = false;
  bool isLoadingAdFree = true;

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _listenToCart();
    _listenToRecentOrders();
    _fetchAdFreeStatus();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }

  void _listenToCart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    _cartSubscription = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (mounted) {
        final data = doc.data();
        setState(() {
          if (data != null && data.containsKey('items')) {
            final items = data['items'] as List?;
            cartCount = items?.length ?? 0;
          } else {
            cartCount = 0;
          }
        });
      }
    }, onError: (error) {
      print('Error listening to cart: $error');
    });
  }

  void _listenToRecentOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .where('paymentStatus', isEqualTo: 'paid') // Only paid orders
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        recentOrders = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        // Show badge if there are new paid orders and not marked as read
        notificationCount = notificationsRead ? 0 : recentOrders.length;
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
      MaterialPageRoute(builder: (_) => NotificationsPage(orders: recentOrders)),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> product, String productId) async {
    print('Add to Cart tapped for productId: $productId');
    final user = FirebaseAuth.instance.currentUser;
    print('Current user:  [33m${user?.uid} [0m');
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add items to cart')),
      );
      return;
    }
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(user.uid);
    try {
      // --- REPLACEMENT: Use get and set instead of transaction for web compatibility ---
      final cartDoc = await cartRef.get();
      List items = (cartDoc.data()?['items'] as List?) ?? [];
      final index = items.indexWhere((item) => item['productId'] == productId);
      if (index >= 0) {
        items[index]['quantity'] = (items[index]['quantity'] ?? 1) + 1;
      } else {
        // Always fetch sellerId from products collection
        final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
        final sellerId = productDoc.data()?['sellerId'];
        items.add({
          'productId': productId,
          'name': product['name'],
          'price': product['price'],
          'imageUrl': product['imageUrl'],
          'category': product['category'],
          'quantity': 1,
          'sellerId': sellerId, // <-- Always include sellerId
        });
      }
      await cartRef.set({'items': items, 'lastUpdated': FieldValue.serverTimestamp()});
      print('Product added to cart in Firestore!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product['name']} added to cart!'), backgroundColor: Colors.green),
      );
    } on TimeoutException catch (e) {
      print('Timeout when adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network timeout. Please check your connection and try again.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add item to cart. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  void _openCartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerCartPage(
          onOrderPlaced: () {
            setState(() {
              notificationsRead = false;
            });
          },
        ),
      ),
    );
  }

  Future<double> getTotalCommissionFromBuyer(String buyerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: buyerId)
        .where('paymentStatus', isEqualTo: 'paid')
        .get();

    double totalCommission = 0.0;
    for (var doc in snapshot.docs) {
      final commissions = (doc['commissions'] as List?) ?? [];
      for (final c in commissions) {
        if (c is Map && c['amount'] is num) {
          totalCommission += (c['amount'] as num).toDouble();
        }
      }
    }
    return totalCommission;
  }

  Future<void> _fetchAdFreeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isAdFree = false;
        isLoadingAdFree = false;
      });
      return;
    }
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      isAdFree = (userDoc['isAdFree'] == true) || (userDoc['isPremium'] == true);
      isLoadingAdFree = false;
    });
  }

  // Demo BannerAd widget for free users with marquee text
  Widget _adBannerWidget() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: Colors.yellow[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, color: Colors.orange[800], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 30,
                child: Marquee(
                  text: '🔥 Hot Deals! Get the best tech at unbeatable prices! Limited time offers! 🔥',
                  style: TextStyle(fontSize: 18, color: Colors.orange[900], fontWeight: FontWeight.bold),
                  velocity: 40.0,
                  blankSpace: 60.0,
                  pauseAfterRound: Duration(seconds: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[900]!;
    final buyerId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white),
            const SizedBox(width: 8),
            const Text('TechBuy'),
            if (!isLoadingAdFree && isAdFree)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Chip(
                  label: const Text('Ad-Free', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green[700],
                  avatar: const Icon(Icons.block, color: Colors.white),
                ),
              ),
          ],
        ),
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                tooltip: 'Cart',
                onPressed: _openCartPage,
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
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
                  Text('Buyer', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context), // Already on home
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('My Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderHistoryPage()),
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
                  MaterialPageRoute(builder: (context) => const BuyerProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Order History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderHistoryPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (buyerId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: FutureBuilder<double>(
                  future: getTotalCommissionFromBuyer(buyerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(Icons.percent, color: Colors.red[700], size: 32),
                              const SizedBox(width: 16),
                              const CircularProgressIndicator(strokeWidth: 2),
                              const SizedBox(width: 16),
                              const Text('Total Commission', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(Icons.percent, color: Colors.red[700], size: 32),
                              const SizedBox(width: 16),
                              Text('0.00', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[700])),
                              const SizedBox(width: 16),
                              const Text('Total Commission', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      );
                    }
                    double commission = snapshot.data ?? 0.0;
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.percent, color: Colors.red[700], size: 32),
                            const SizedBox(width: 16),
                            Text('FRW ${commission.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[700])),
                            const SizedBox(width: 16),
                            const Text('Total Commission', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Always show the ad banner for testing
            _adBannerWidget(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Text(
                'Available Products',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search Products',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  // Force rebuild
                  (context as Element).markNeedsBuild();
                },
              ),
            ),
            const SizedBox(height: 12),
            // Category chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (_) {
                        selectedCategory = cat;
                        (context as Element).markNeedsBuild();
                      },
                      selectedColor: themeColor.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: selectedCategory == cat ? themeColor : Colors.black,
                        fontWeight: selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No products available.', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final product = filteredProducts[i];
                      final data = product.data() as Map<String, dynamic>;
                      final imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : '';
                      final stock = data.containsKey('stock') ? data['stock'] : 'N/A';
                      final specs = data.containsKey('specs') ? data['specs'] : '';
                      return Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: (imageUrl != null && imageUrl.isNotEmpty)
                                        ? Image.network(
                                            imageUrl,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return SizedBox(
                                                width: 80,
                                                height: 80,
                                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[200],
                                            child: Icon(Icons.devices_other, color: themeColor, size: 40),
                                          ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? '',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Category: ${data['category'] ?? ''}', style: TextStyle(fontSize: 15)),
                                        Text('Price: FRW ${data['price']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontSize: 15, color: Colors.green[700], fontWeight: FontWeight.w600)),
                                        Text('Stock: $stock', style: TextStyle(fontSize: 15)),
                                        if (specs.toString().isNotEmpty) Text('Specs: $specs', style: TextStyle(fontSize: 15)),
                                        if (data.containsKey('description') && data['description'] != null && data['description'].toString().isNotEmpty)
                                          Text('Description: ${data['description']}', style: TextStyle(fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(data['name'] ?? ''),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (imageUrl != null && imageUrl.isNotEmpty)
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    imageUrl,
                                                    width: 180,
                                                    height: 180,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              const SizedBox(height: 8),
                                              Text('Category: ${data['category'] ?? ''}'),
                                              Text('Price: FRW ${data['price']?.toStringAsFixed(2) ?? '0.00'}'),
                                              Text('Stock: $stock'),
                                              Text('Specs: $specs'),
                                              Text('Description: ${data['description'] ?? ''}'),
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
                                    },
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('View Details'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[700],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onPressed: () => _addToCart(data, product.id),
                                    icon: const Icon(Icons.add_shopping_cart),
                                    label: const Text('Add to Cart'),
                                  ),
                                ],
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
      ),
    );
  }
}

// Cart Page
class BuyerCartPage extends StatelessWidget {
  final VoidCallback? onOrderPlaced;
  const BuyerCartPage({Key? key, this.onOrderPlaced}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeColor = Colors.blue[900]!;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: Text('Please log in to view your cart')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: themeColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('carts').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading cart'));
          }
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final items = (data?['items'] as List?) ?? [];
          print('Cart items: $items');
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Add some products to get started!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Continue Shopping'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          double total = 0;
          for (final item in items) {
            total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                                  ? Image.network(
                                      item['imageUrl'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: Icon(Icons.devices_other, color: themeColor, size: 30),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: Icon(Icons.devices_other, color: themeColor, size: 30),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Unknown Product',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'FRW ${(item['price'] ?? 0).toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity: ${item['quantity'] ?? 1}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Remove',
                              onPressed: () => _removeFromCart(context, user.uid, item['productId']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'FRW ${total.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _checkout(context, user.uid),
                        icon: const Icon(Icons.payment),
                        label: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removeFromCart(BuildContext context, String userId, String productId) async {
    try {
      final cartRef = FirebaseFirestore.instance.collection('carts').doc(userId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final cartDoc = await transaction.get(cartRef);
        
        if (cartDoc.exists) {
          final data = cartDoc.data();
          List items = (data?['items'] as List?) ?? [];
          items.removeWhere((item) => item['productId'] == productId);
          
          transaction.set(cartRef, {
            'items': items,
            'lastUpdated': FieldValue.serverTimestamp()
          });
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error removing from cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove item. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkout(BuildContext context, String userId) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      // Get current cart items and total
      final cartRef = FirebaseFirestore.instance.collection('carts').doc(userId);
      final cartDoc = await cartRef.get();
      final data = cartDoc.data() as Map<String, dynamic>?;
      final items = (data?['items'] as List?) ?? [];
      double total = 0;
      // Ensure each item has a sellerId (fetch from product if missing)
      List<Map<String, dynamic>> updatedItems = [];
      for (final item in items) {
        total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
        // If sellerId is missing, fetch from products collection
        if (item['sellerId'] == null) {
          final productDoc = await FirebaseFirestore.instance.collection('products').doc(item['productId']).get();
          final sellerId = productDoc.data()?['sellerId'];
          updatedItems.add({...item, 'sellerId': sellerId});
        } else {
          updatedItems.add(item);
        }
      }
      // Save order to Firestore
      final ordersRef = FirebaseFirestore.instance.collection('orders');
      // Collect all unique sellerIds from items
      final sellerIds = updatedItems.map((item) => item['sellerId']).toSet().toList();
      // Calculate commission for each seller
      const double commissionRate = 0.05; // 5%
      final sellerCommissions = <Map<String, dynamic>>[];
      for (final sellerId in sellerIds) {
        final sellerItems = updatedItems.where((item) => item['sellerId'] == sellerId).toList();
        final sellerTotal = sellerItems.fold(0.0, (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)));
        final commission = sellerTotal * commissionRate;
        sellerCommissions.add({
          'sellerId': sellerId,
          'amount': commission,
        });
      }
      final orderRef = await ordersRef.add({
        'userId': userId,
        'items': updatedItems,
        'total': total,
        'timestamp': FieldValue.serverTimestamp(),
        'sellerIds': sellerIds,
        'status': 'pending',
        'paymentStatus': 'pending',
        'commissions': sellerCommissions,
      });
      // Clear the cart
      await cartRef.set({
        'items': [],
        'lastUpdated': FieldValue.serverTimestamp()
      });
      // Notify dashboard to show notification badge
      if (onOrderPlaced != null) {
        onOrderPlaced!();
      }
      // Close loading dialog
      Navigator.pop(context);
      // Navigate to DemoPaymentPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemoPaymentPage(orderId: orderRef.id, total: total),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      print('Error during checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// --- Order History Page ---
class OrderHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeColor = Colors.blue[900]!;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order History')),
        body: const Center(child: Text('Please log in to view your orders')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: themeColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading orders'));
          }
          final orders = snapshot.data?.docs ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final total = data['total'] ?? 0;
              final items = (data['items'] as List?) ?? [];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.receipt_long, color: themeColor, size: 32),
                  title: Text('Order on ${timestamp != null ? DateFormat('yMMMd').add_jm().format(timestamp) : 'Unknown date'}'),
                  subtitle: Text('Total: FRW ${total.toStringAsFixed(2)}\nItems: ${items.length}'),
                  isThreeLine: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Order Details'),
                        content: SizedBox(
                          width: 300,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order Date: ${timestamp != null ? DateFormat('yMMMd').add_jm().format(timestamp) : 'Unknown'}'),
                              Text('Total: FRW ${total.toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('${item['name']} x${item['quantity']} (FRW ${item['price']?.toStringAsFixed(2) ?? '0.00'})'),
                              )),
                            ],
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
          );
        },
      ),
    );
  }
}

// --- Notifications Page ---
class NotificationsPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const NotificationsPage({Key? key, required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[900]!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: themeColor,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('No notifications.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final timestamp = (order['timestamp'] is Timestamp)
                    ? (order['timestamp'] as Timestamp).toDate()
                    : null;
                final total = order['total'] ?? 0;
                final items = (order['items'] as List?) ?? [];
                final paymentMethod = order['paymentMethod'] ?? 'N/A';
                final paymentNumber = order['paymentNumber'] ?? '';
                final orderStatus = order['status'] ?? 'N/A';
                final orderId = order['orderId'] ?? '';
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(Icons.payment, color: themeColor),
                    title: Text('Payment Successful! (Order: ${orderId.isNotEmpty ? orderId : 'N/A'})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You paid with: $paymentMethod'),
                        if (paymentNumber.isNotEmpty)
                          Text('Number/Email: $paymentNumber'),
                        Text('Order Status: $orderStatus'),
                        Text('Total: FRW ${total.toStringAsFixed(2)}'),
                        Text('Items: ${items.length}'),
                        if (timestamp != null)
                          Text('Paid on: ${DateFormat('yMMMd').add_jm().format(timestamp)}'),
                        const SizedBox(height: 8),
                        const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${item['name']} x${item['quantity']} (FRW ${item['price']?.toStringAsFixed(2) ?? '0.00'})'),
                        )),
                      ],
                    ),
                    isThreeLine: true,
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
                                  Text('Order ID: ${orderId.isNotEmpty ? orderId : 'N/A'}'),
                                  Text('Order Status: $orderStatus'),
                                  Text('Payment Method: $paymentMethod'),
                                  if (paymentNumber.isNotEmpty)
                                    Text('Number/Email: $paymentNumber'),
                                  Text('Total: FRW ${total.toStringAsFixed(2)}'),
                                  if (timestamp != null)
                                    Text('Paid on: ${DateFormat('yMMMd').add_jm().format(timestamp)}'),
                                  const SizedBox(height: 8),
                                  const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...items.map((item) => Padding(
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
