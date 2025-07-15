import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'registration_screen.dart'; // Added import for RegistrationScreen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

// Returns the active discount as a decimal (e.g., 0.5 for 50% off). Update logic as needed for dynamic offers.
double getActiveDiscount() {
  // Example: If the '50% Off!' offer is present, return 0.5
  // You can make this dynamic by checking the offers list or other logic
  return 0.5; // 50% off for demonstration
}

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({Key? key}) : super(key: key);

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  String selectedCategory = 'Clothes';
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  final List<Map<String, dynamic>> cart = [];
  final List<Map<String, dynamic>> purchaseHistory = [];
  final List<Map<String, dynamic>> wishlist = [];
  final List<String> notifications = [];
  List<Map<String, dynamic>> _notificationsCache = [];
  final GlobalKey cartKey = GlobalKey();
  final GlobalKey purchaseHistoryKey = GlobalKey();
  final Set<String> loadingCartItems = {};
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshNotifications();
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allow full height and scrolling
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ProductDetailsModal(product: product, buyerName: FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown Buyer');
      },
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notifications.isEmpty)
              const Text('No notifications.'),
            for (final note in notifications)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(note),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RegistrationScreen()),
      );
      return;
    }
    final id = product['id'] ?? product['name'];
    setState(() {
      loadingCartItems.add(id);
    });
    // Simulate async work (or replace with real async if needed)
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        cart.add(product);
        loadingCartItems.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} added to cart!'),
          action: SnackBarAction(
            label: 'Go to Cart',
            onPressed: () {
              Scrollable.ensureVisible(
                cartKey.currentContext ?? context,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
      );
    });
  }

  void _showPaymentMethods(BuildContext context, double total, [double discount = 0]) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedMethod = 'Airtel Money'; // Default selection
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Select Payment Method'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (discount > 0)
                  Text('Discount applied: -RWF ${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text('Total to pay: RWF ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Airtel Money'),
                  value: 'Airtel Money',
                  groupValue: selectedMethod,
                  onChanged: (val) => setState(() => selectedMethod = val),
                ),
                RadioListTile<String>(
                  title: const Text('MTN'),
                  value: 'MTN',
                  groupValue: selectedMethod,
                  onChanged: (val) => setState(() => selectedMethod = val),
                ),
                RadioListTile<String>(
                  title: const Text('Bank'),
                  value: 'Bank',
                  groupValue: selectedMethod,
                  onChanged: (val) => setState(() => selectedMethod = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedMethod == null
                    ? null
                    : () async {
                        Navigator.pop(context); // Close payment method dialog

                        final user = FirebaseAuth.instance.currentUser;
                        final buyerName = user?.displayName ?? user?.email ?? 'Unknown Buyer';
                        final buyerId = user?.uid ?? '';
                        bool success = false;
                        String? errorMsg;
                        try {
                          final double commission = total * 0.05;
                          final double sellerEarnings = total - commission;
                          final orderRef = await FirebaseFirestore.instance.collection('orders')
                            .add({
                              'items': List<Map<String, dynamic>>.from(cart),
                              'total': total,
                              'discount': discount,
                              'commission': commission,
                              'sellerEarnings': sellerEarnings,
                              'method': selectedMethod,
                              'date': DateTime.now(),
                              'createdAt': FieldValue.serverTimestamp(),
                              'buyerName': buyerName,
                              'buyerId': buyerId,
                              'status': 'Pending',
                            })
                            .timeout(const Duration(seconds: 2), onTimeout: () {
                              throw Exception('Payment timed out. Please check your connection and try again.');
                            });
                          // Send notification to buyer's notifications subcollection
                          await FirebaseFirestore.instance.collection('users').doc(buyerId).collection('notifications').add({
                            'message': 'Payment successful!',
                            'timestamp': DateTime.now(),
                            'orderId': orderRef.id,
                            'status': 'Paid',
                          });
                          success = true;
                          setState(() {
                            notifications.add('Paid RWF ${total.toStringAsFixed(2)} via $selectedMethod successfully!');
                            purchaseHistory.add({
                              'items': List<Map<String, dynamic>>.from(cart),
                              'total': total,
                              'discount': discount,
                              'method': selectedMethod,
                              'date': DateTime.now(),
                              'buyerName': buyerName,
                              'buyerId': buyerId,
                              'status': 'Pending',
                            });
                            cart.clear();
                          });
                        } catch (e) {
                          errorMsg = e.toString();
                        } finally {
                          // Dismiss loading spinner
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (success) {
                          String confirmationMsg = 'Paid successfully!';
                          if (selectedMethod == 'MTN') {
                            confirmationMsg = 'Paid successfully with MTN!';
                          } else if (selectedMethod == 'Airtel Money') {
                            confirmationMsg = 'Paid successfully with Airtel Money!';
                          } else if (selectedMethod == 'Bank') {
                            confirmationMsg = 'Paid successfully with Bank!';
                          }
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Simulated Payment'),
                              content: Text('Payment successful via MTN Mobile Money.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          // Also show a snackbar for extra feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(confirmationMsg)),
                          );
                        } else if (errorMsg != null) {
                          // Show error dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Payment Error'),
                              content: Text(errorMsg!),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                child: const Text('Pay'),
              ),
            ],
          ),
        );
      },
    );
  }

  double _statusToProgress(String status) {
    switch (status) {
      case 'Pending':
        return 0.25;
      case 'Processing':
        return 0.5;
      case 'Shipped':
        return 0.75;
      case 'Delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserNotifications({bool showDeliveryMessage = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .get();
    final notifList = snap.docs.map((d) => d.data()).toList();
    if (showDeliveryMessage) {
      final deliveredNotifs = notifList.where((n) => n['status'] == 'Delivered').toList();
      if (deliveredNotifs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your product was delivered successfully!')),
          );
        });
      }
    }
    return notifList;
  }

  Future<void> _refreshNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .get();
    setState(() {
      _notificationsCache = snap.docs.map((d) => d.data()).toList();
    });
  }

  final List<Map<String, String>> offers = [
    {
      'title': '50% Off!',
      'description': 'Get 50% off on all shoes, clothes this week!'
    }
  ];

  void _showOffers(BuildContext context) {
    if (offers.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Offers'),
          content: Text('No offers available at the moment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Offers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: offers.map((offer) => ListTile(
              title: Text(offer['title'] ?? ''),
              subtitle: Text(offer['description'] ?? ''),
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building BuyerDashboard');
    return Scaffold(
      backgroundColor: const Color(0xFF7F7FD5),
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('BerwaStore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            const Spacer(),
          ],
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.red),
                tooltip: 'Notifications',
                onPressed: () async {
                  await _refreshNotifications();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Notifications'),
                      content: SizedBox(
                        width: 300,
                        child: _notificationsCache.isEmpty
                            ? const Text('No notifications.')
                            : ListView(
                                shrinkWrap: true,
                                children: [
                                  for (final note in _notificationsCache)
                                    ListTile(
                                      leading: const Icon(Icons.notifications, color: Colors.blue),
                                      title: Text(note['message'] ?? ''),
                                      subtitle: note['timestamp'] != null
                                          ? Text((note['timestamp'] is Timestamp
                                              ? (note['timestamp'] as Timestamp).toDate().toLocal().toString().split('.')[0]
                                              : note['timestamp'].toString()))
                                          : null,
                                    ),
                                ],
                              ),
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                    ),
                  );
                },
              ),
              if (_notificationsCache.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        _notificationsCache.length > 99 ? '99+' : '${_notificationsCache.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Card
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('BerwaStore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        const Spacer(),
                      ],
                    ),
                    // Notification icon removed
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickActionCard(
                      icon: Icons.sync,
                      label: 'Order Tracker',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrderTrackerScreen()),
                        );
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.receipt_long,
                      label: 'Purchase History',
                      onTap: () {
                        // Scroll to purchase history section
                        Scrollable.ensureVisible(
                          purchaseHistoryKey.currentContext ?? context,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.rate_review,
                      label: 'Review',
                      onTap: () {
                        _feedbackController.clear();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Leave Feedback'),
                            content: TextField(
                              controller: _feedbackController,
                              decoration: const InputDecoration(hintText: 'Enter your feedback...'),
                              maxLines: 3,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final text = _feedbackController.text.trim();
                                  if (text.isNotEmpty) {
                                    Navigator.pop(context);
                                    setState(() {
                                      notifications.add('Feedback: $text');
                                    });
                                  }
                                },
                                child: const Text('Submit'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.card_giftcard,
                      label: 'Offers',
                      onTap: () {
                        _showOffers(context);
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.language,
                      label: 'Settings',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Settings'),
                            content: const Text('Language and currency settings coming soon!'),
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
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search shoes, clothes...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 18),
                // Categories
                const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'Clothes',
                        icon: Icons.checkroom,
                        selected: selectedCategory == 'Clothes',
                        onTap: () => setState(() => selectedCategory = 'Clothes'),
                      ),
                      _CategoryChip(
                        label: 'Jeans',
                        icon: Icons.roller_shades,
                        selected: selectedCategory == 'Jeans',
                        onTap: () => setState(() => selectedCategory = 'Jeans'),
                      ),
                      _CategoryChip(
                        label: 'Dresses',
                        icon: Icons.checkroom,
                        selected: selectedCategory == 'Dresses',
                        onTap: () => setState(() => selectedCategory = 'Dresses'),
                      ),
                      _CategoryChip(
                        label: 'Shoes',
                        icon: Icons.directions_run,
                        selected: selectedCategory == 'Shoes',
                        onTap: () => setState(() => selectedCategory = 'Shoes'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Popular Products
                const Text('Popular Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    print('Products StreamBuilder state: ${snapshot.connectionState}, hasError: ${snapshot.hasError}, hasData: ${snapshot.hasData}');
                    if (snapshot.hasError) {
                      print('Products StreamBuilder error: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text('Error loading products: ${snapshot.error}'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  // Trigger rebuild
                                });
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading products...'),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, color: Colors.grey, size: 48),
                            SizedBox(height: 16),
                            Text('No products found.'),
                            SizedBox(height: 8),
                            Text('Products will appear here once added.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    final products = snapshot.data!.docs;
                    final filteredProducts = products.where((p) {
                      final map = Map<String, dynamic>.from(p.data() as Map);
                      final category = (map['category'] ?? '').toString().toLowerCase();
                      final selected = selectedCategory.toLowerCase();
                      final matchesCategory = category.isEmpty || category == selected;
                      final matchesSearch = searchQuery.isEmpty ||
                        (map['name'] ?? '').toString().toLowerCase().contains(searchQuery);
                      return matchesCategory && matchesSearch;
                    }).toList();
                    final Map<String, Map<String, dynamic>> allProductsById = {
                      for (var p in filteredProducts)
                        (p.id ?? (Map<String, dynamic>.from(p.data() as Map)['name'])): Map<String, dynamic>.from(p.data() as Map),
                    };
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.65, // lower aspect ratio for shorter cards
                      children: [
                        for (var p in filteredProducts)
                          Builder(
                            builder: (context) {
                              final map = Map<String, dynamic>.from(p.data() as Map);
                              final double originalPrice = double.tryParse(map['price'].toString()) ?? 0;
                              final double discount = getActiveDiscount();
                              final double discountedPrice = discount > 0 ? originalPrice * (1 - discount) : originalPrice;
                              return _ProductCard(
                                name: map['name'] ?? '',
                                price: discountedPrice.toStringAsFixed(2),
                                originalPrice: originalPrice.toStringAsFixed(2),
                                hasDiscount: discount > 0,
                                imagePath: map['imageUrl'] ?? '',
                                icon: null,
                                color: Colors.blue,
                                onTap: () => _showProductDetails(context, map),
                                onAddToCart: () => _addToCart(map),
                                wishlistIcon: IconButton(
                                  icon: Icon(
                                    wishlist.any((p) => p['name'] == map['name']) ? Icons.favorite : Icons.favorite_border,
                                    color: wishlist.any((p) => p['name'] == map['name']) ? Colors.pink : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (wishlist.any((p) => p['name'] == map['name'])) {
                                        wishlist.removeWhere((p) => p['name'] == map['name']);
                                      } else {
                                        wishlist.add(map);
                                      }
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          wishlist.any((p) => p['name'] == map['name'])
                                            ? '${map['name']} added to wishlist!'
                                            : '${map['name']} removed from wishlist!'
                                        ),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Cart Section
                if (cart.isNotEmpty) ...[
                  Container(
                    key: cartKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cart.length,
                          itemBuilder: (context, i) {
                            final item = cart[i];
                            final id = item['id'] ?? item['name'];
                            return ListTile(
                              leading: item['imagePath'] != null ? CircleAvatar(backgroundImage: AssetImage(item['imagePath'])) : null,
                              title: Text(item['name']),
                              subtitle: getActiveDiscount() > 0
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('RWF ${(double.tryParse(item['price'].toString())! * (1 - getActiveDiscount())).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                                      Text('RWF ${item['price']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal)),
                                    ],
                                  )
                                : Text('RWF ${item['price']}'),
                              trailing: loadingCartItems.contains(id)
                                  ? const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          cart.removeAt(i);
                                        });
                                      },
                                    ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            double total = 0;
                            for (var item in cart) {
                              total += double.tryParse(item['price'].toString().trim()) ?? 0;
                            }
                            double discount = 0;
                            if (cart.length > 3) {
                              discount = total * 0.10;
                            }
                            double finalTotal = total - discount;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total: RWF ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (discount > 0)
                                  Text('Discount (10%): -RWF ${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                if (discount > 0)
                                  Text('New Total: RWF ${finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showPaymentMethods(context, finalTotal, discount);
                                    },
                                    child: const Text('Checkout'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
                // Purchase History Section
                Container(
                  key: purchaseHistoryKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Purchase History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseAuth.instance.currentUser == null
                          ? null
                          : FirebaseFirestore.instance
                              .collection('orders')
                              .where('buyerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                              .orderBy('date', descending: true)
                              .snapshots(),
                        builder: (context, snapshot) {
                          print('Purchase history StreamBuilder state: ${snapshot.connectionState}, hasError: ${snapshot.hasError}, hasData: ${snapshot.hasData}');
                          if (snapshot.hasError) {
                            print('Purchase history StreamBuilder error: ${snapshot.error}');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 32),
                                  SizedBox(height: 8),
                                  Text('Error loading purchases: ${snapshot.error}'),
                                ],
                              ),
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Loading purchases...', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, color: Colors.grey, size: 32),
                                  SizedBox(height: 8),
                                  Text('No purchases yet.', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          }
                          final orders = snapshot.data!.docs;
                          return SizedBox(
                            height: 250,
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: orders.length,
                              itemBuilder: (context, i) {
                                final order = orders[i].data() as Map<String, dynamic>;
                                final items = (order['items'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();
                                final date = order['date'] is Timestamp
                                  ? (order['date'] as Timestamp).toDate()
                                  : order['date'] as DateTime?;
                                final feedback = order['feedback'] as String?;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Text('Total: RWF ${order['total'].toStringAsFixed(2)}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Paid via: ${order['method']}'),
                                        if ((order['discount'] ?? 0) > 0)
                                          Text('Discount: RWF ${order['discount'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                                        if (date != null)
                                          Text('Date: ${date.toLocal().toString().split(".")[0]}'),
                                        Text('Status: ${order['status'] ?? 'Pending'}'),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: LinearProgressIndicator(
                                            value: _statusToProgress(order['status'] ?? 'Pending'),
                                            backgroundColor: Colors.grey[300],
                                            color: Colors.blue,
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Items:'),
                                        ...items.map((item) => Text('- ${item['name']} (RWF ${item['price']})')),
                                        const SizedBox(height: 6),
                                        if (feedback != null && feedback.isNotEmpty)
                                          Text('Feedback: $feedback', style: const TextStyle(color: Colors.blue)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _logout(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, color: selected ? Colors.white : Colors.blue, size: 18),
        label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.blue)),
        selected: selected,
        selectedColor: Colors.blue,
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final String name;
  final String price;
  final String originalPrice;
  final bool hasDiscount;
  final String? imagePath;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onUpdate;
  final Widget? wishlistIcon;
  const _ProductCard({
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.hasDiscount,
    this.imagePath,
    this.icon,
    required this.color,
    this.onTap,
    this.onAddToCart,
    this.onUpdate,
    this.wishlistIcon
  });
  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  double _scale = 1.0;
  bool _isAnimating = false;

  void _animateButton(VoidCallback? onPressed) async {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      _scale = 0.92;
    });
    await Future.delayed(const Duration(milliseconds: 120));
    setState(() {
      _scale = 1.0;
    });
    await Future.delayed(const Duration(milliseconds: 80));
    setState(() {
      _isAnimating = false;
    });
    if (onPressed != null) onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                    CircleAvatar(
                      backgroundColor: widget.color.withOpacity(0.15),
                      radius: 28,
                      backgroundImage: widget.imagePath!.startsWith('assets/')
                        ? AssetImage(widget.imagePath!) as ImageProvider
                        : NetworkImage(widget.imagePath!),
                    )
                  else if (widget.icon != null)
                    CircleAvatar(
                      backgroundColor: widget.color.withOpacity(0.15),
                      radius: 28,
                      child: Icon(widget.icon, color: widget.color, size: 32),
                    ),
                  const SizedBox(height: 8),
                  Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  if (widget.hasDiscount)
                    Column(
                      children: [
                        Text('RWF ${widget.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        Text(
                          'RWF ${widget.originalPrice}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    )
                  else
                    Text('RWF ${widget.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  if (widget.wishlistIcon != null)
                    widget.wishlistIcon!,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.onAddToCart != null)
                        AnimatedScale(
                          scale: _scale,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeInOut,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isAnimating ? null : () => _animateButton(widget.onAddToCart),
                          ),
                        ),
                      if (widget.onUpdate != null)
                        const SizedBox(width: 8),
                      if (widget.onUpdate != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Update', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: widget.onUpdate,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.hasDiscount)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '50% Off',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Icon(icon, color: Colors.blue, size: 28),
            radius: 24,
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class OrderTrackerScreen extends StatelessWidget {
  const OrderTrackerScreen({Key? key}) : super(key: key);

  double _statusToProgress(String status) {
    switch (status) {
      case 'Pending':
        return 0.25;
      case 'Processing':
        return 0.5;
      case 'Shipped':
        return 0.75;
      case 'Delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracker'),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('buyerId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                print('Snapshot state: ${snapshot.connectionState}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }
                final orders = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final order = orders[i].data() as Map<String, dynamic>;
                    final status = order['status'] ?? 'Pending';
                    final date = order['date'] is Timestamp
                        ? (order['date'] as Timestamp).toDate()
                        : order['date'] as DateTime?;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Total: RWF ${order['total'].toStringAsFixed(2)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: $status'),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: LinearProgressIndicator(
                                value: _statusToProgress(status),
                                backgroundColor: Colors.grey[300],
                                color: Colors.blue,
                                minHeight: 6,
                              ),
                            ),
                            if (date != null)
                              Text('Date: ${date.toLocal().toString().split(".")[0]}'),
                            const SizedBox(height: 4),
                            Text('Items:'),
                            ...((order['items'] as List<dynamic>).map((item) {
                              final map = Map<String, dynamic>.from(item as Map);
                              return Text('- ${map['name']} (RWF ${map['price']})');
                            })),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class WishlistScreen extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const WishlistScreen({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: products.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, i) {
                final product = products[i];
                return ListTile(
                  leading: product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(product['imageUrl']))
                      : null,
                  title: Text(product['name'] ?? ''),
                  subtitle: getActiveDiscount() > 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RWF ${(double.tryParse(product['price'].toString())! * (1 - getActiveDiscount())).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                            Text('RWF ${product['price']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal)),
                          ],
                        )
                      : Text('RWF ${product['price']}'),
                );
              },
            ),
    );
  }
}

class ProductDetailsModal extends StatefulWidget {
  final Map<String, dynamic> product;
  final String buyerName;
  const ProductDetailsModal({Key? key, required this.product, required this.buyerName}) : super(key: key);

  @override
  State<ProductDetailsModal> createState() => _ProductDetailsModalState();
}

class _ProductDetailsModalState extends State<ProductDetailsModal> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _submitting = false;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final snap = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product['id'] ?? widget.product['name'])
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();
    final reviews = snap.docs.map((d) => d.data()).toList();
    double avg = 0;
    if (reviews.isNotEmpty) {
      avg = reviews.map((r) => (r['rating'] ?? 0) as num).reduce((a, b) => a + b) / reviews.length;
    }
    setState(() {
      _reviews = List<Map<String, dynamic>>.from(reviews);
      _averageRating = avg;
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0 || _reviewController.text.trim().isEmpty) return;
    setState(() { _submitting = true; });
    final review = {
      'userName': widget.buyerName,
      'rating': _rating,
      'reviewText': _reviewController.text.trim(),
      'timestamp': DateTime.now(),
    };
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product['id'] ?? widget.product['name'])
        .collection('reviews')
        .add(review);
    setState(() { _submitting = false; });
    Navigator.pop(context);
    _fetchReviews();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 64), // even more bottom padding
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.product['imageUrl'] != null && widget.product['imageUrl'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(widget.product['imageUrl'], height: 120),
                ),
              const SizedBox(height: 16),
              Text(widget.product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              if (getActiveDiscount() > 0)
                Column(
                  children: [
                    Text('RWF ${(double.tryParse(widget.product['price'].toString())! * (1 - getActiveDiscount())).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Text('RWF ${widget.product['price']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal)),
                  ],
                )
              else
                Text('RWF ${widget.product['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 8),
              Text(widget.product['description'] ?? 'No description available.'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_averageRating > 0)
                    Row(
                      children: [
                        for (int i = 1; i <= 5; i++)
                          Icon(
                            i <= _averageRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        const SizedBox(width: 6),
                        Text(_averageRating.toStringAsFixed(1)),
                      ],
                    )
                  else
                    const Text('No ratings yet'),
                ],
              ),
              const SizedBox(height: 12),
              if (_reviews.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Reviews:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final r in _reviews)
                          ListTile(
                            leading: Icon(Icons.person, color: Colors.blue),
                            title: Row(
                              children: [
                                for (int i = 1; i <= 5; i++)
                                  Icon(
                                    i <= (r['rating'] ?? 0).round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                const SizedBox(width: 6),
                                Text(r['userName'] ?? ''),
                              ],
                            ),
                            subtitle: Text(r['reviewText'] ?? ''),
                          ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.rate_review),
                label: const Text('Leave a Review'),
                onPressed: _submitting
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Leave a Review'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (int i = 1; i <= 5; i++)
                                      IconButton(
                                        icon: Icon(
                                          i <= _rating ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                        ),
                                        onPressed: () => setState(() => _rating = i.toDouble()),
                                      ),
                                  ],
                                ),
                                TextField(
                                  controller: _reviewController,
                                  decoration: const InputDecoration(hintText: 'Write your review...'),
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
                                onPressed: _submitting ? null : _submitReview,
                                child: _submitting
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Submit'),
                              ),
                            ],
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}         