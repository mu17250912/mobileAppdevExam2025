import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import 'cart_page.dart';
import '../support/client_support_screen.dart';
import 'order_history_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'product_details_screen.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';

const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kBackgroundColor = Color(0xFFF5F6FA);
const String kStoreName = 'ElectroMat';
const String kLogoUrl = 'assets/phonestorelogo.jpg';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  ThemeMode _themeMode = ThemeMode.light;
  int _selectedIndex = 0;
  int _cartItemCount = 0;
  int _notificationCount = 0;
  String _searchQuery = '';
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _listenToCartCount();
    _listenToNotificationCount();
  }

  void _listenToCartCount() {
    _cartService.getCartItemCount().then((count) {
      if (mounted) {
        setState(() {
          _cartItemCount = count;
        });
      }
    });
  }

  void _listenToNotificationCount() {
    NotificationService.getUnreadNotificationCount().listen((count) {
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    });
  }

  Future<void> _addToCart(Product product, String userId) async {
    try {
      if (!product.inStock) {
        return;
      }

      // Log add to cart event
      await FirebaseAnalytics.instance.logEvent(
        name: 'add_to_cart',
        parameters: {
          'product_id': product.id,
          'product_name': product.name,
          'price': product.price,
          'buyer_id': userId,
        },
      );

      // Check stock availability
      final currentCartItems = await _cartService.getCartItems().first;
      final existingItem = currentCartItems.firstWhere(
        (item) => item.productId == product.id,
        orElse: () => CartItem(
          id: '',
          productId: product.id,
          name: product.name,
          price: product.price,
          imageUrl: product.imageUrl,
          quantity: 0,
          sellerId: product.sellerId,
          addedAt: DateTime.now(),
        ),
      );

      final newQuantity = existingItem.quantity + 1;
      if (product.stock != null && newQuantity > product.stock!) {
        return;
      }

      // Create cart item
      final cartItem = CartItem(
        id: product.id,
        productId: product.id,
        name: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        quantity: 1,
        sellerId: product.sellerId,
        addedAt: DateTime.now(),
      );

      await _cartService.addToCart(cartItem);
      
      // Update cart count
      _listenToCartCount();
    } catch (e) {
      // Add to cart error
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onMenuSelected(String choice) {
    switch (choice) {
      case 'order_history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
        );
        break;
      case 'settings':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings clicked')));
        break;
      case 'help':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ClientSupportScreen()),
        );
        break;
      case 'subscribe':
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Subscribe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Subscribe to our newsletter for the latest updates and offers!',
                ),
                SizedBox(height: 12),
                Text('Thank you for supporting PhoneStore.'),
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
        break;
      case 'toggle_theme':
        setState(() {
          _themeMode = _themeMode == ThemeMode.light
              ? ThemeMode.dark
              : ThemeMode.light;
        });
        break;
    }
  }

  Widget _buildHomeTab(User user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search a product and add to Cart',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var products =
                      snapshot.data?.docs
                          .map((doc) => Product.fromDocument(doc))
                          .toList() ??
                      [];
                  if (_searchQuery.isNotEmpty) {
                    products = products.where((product) {
                      final name = product.name.toLowerCase();
                      final desc = product.description.toLowerCase();
                      return name.contains(_searchQuery) || desc.contains(_searchQuery);
                    }).toList();
                  }
                  if (products.isEmpty) {
                    return const Center(child: Text('No products available'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(product: product),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 10,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: product.imageUrl.isNotEmpty
                                        ? Image.network(
                                            product.imageUrl,
                                            height: 110, // reduced from 140
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 110,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.inStock ? 'In stock' : 'Out of stock',
                                    style: TextStyle(
                                      color: product.inStock ? Colors.green[700] : Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '£${product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Expanded(
                                    child: (product.description.isNotEmpty)
                                        ? Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Text(
                                              product.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: product.inStock
                                          ? () {
                                              _addToCart(product, user.uid);
                                            }
                                          : null,
                                      icon: const Icon(Icons.add_shopping_cart),
                                      label: const Text('Add to Cart'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: product.inStock ? kPrimaryColor : Colors.grey[300],
                                        foregroundColor: product.inStock ? Colors.white : Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab(User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          Text(
            user.displayName ?? 'User',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () async {
              // Log logout event
              await FirebaseAnalytics.instance.logEvent(
                name: 'logout',
                parameters: {
                  'user_id': user.uid,
                },
              );
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages(User user) {
    return [
      _buildHomeTab(user), 
      const CartPage(), 
      const NotificationsScreen(),
      const OrderHistoryScreen(), 
      _buildProfileTab(user)
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 2,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: kPrimaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(kLogoUrl, width: 36, height: 36, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Text(
              kStoreName,
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: kPrimaryColor),
                onPressed: () {
                  setState(() => _selectedIndex = 1);
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kPrimaryColor),
            onSelected: _onMenuSelected,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'order_history', child: Text('Order History')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'help', child: Text('Help & Contact Us')),
              const PopupMenuItem(value: 'subscribe', child: Text('Subscribe')),
              PopupMenuItem(
                value: 'toggle_theme',
                child: Text(_themeMode == ThemeMode.light ? 'Dark Mode' : 'Light Mode'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              accountName: Text(user.displayName ?? 'User'),
              accountEmail: Text(user.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Order History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                // Log logout event
                await FirebaseAnalytics.instance.logEvent(
                  name: 'logout',
                  parameters: {
                    'user_id': user.uid,
                  },
                );
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _buildPages(user)[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
