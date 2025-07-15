import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'register_product_screen.dart';
import 'manage_products_screen.dart';
import '../support/seller_support_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'seller_order_tracking_screen.dart';
import '../models/order.dart' as app_order;
import '../models/cart_item.dart';
import '../clients/chat_screen.dart';
import 'seller_chats_screen.dart';

const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kBackgroundColor = Color(0xFFF5F6FA);
const String kStoreName = 'ElectroMat';
const String kLogoUrl = 'assets/phonestorelogo.jpg';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _selectedIndex = 0;
  bool _isPremiumUser = false;

  @override
  void initState() {
    super.initState();
    _fetchPremiumStatus();
  }

  Future<void> _fetchPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['premium'] == true) {
        setState(() {
          _isPremiumUser = true;
        });
      } else {
        setState(() {
          _isPremiumUser = false;
        });
      }
    }
  }

  // Helper to fetch summary data
  Future<Map<String, dynamic>> _fetchDashboardSummary(String sellerId) async {
    final productsSnap = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .get();
    final products = productsSnap.docs.map((doc) => Product.fromDocument(doc)).toList();
    int totalSold = 0;
    double totalEarnings = 0;
    // TODO: Replace with real order data when order collection is implemented
    // For now, just count stock as sold for demo
    for (final p in products) {
      totalSold += p.stock ?? 0;
      totalEarnings += (p.price ?? 0) * (p.stock ?? 0);
    }
    return {
      'products': products,
      'totalSold': totalSold,
      'totalEarnings': totalEarnings,
    };
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildProfileTab(User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          Text(user.email ?? 'Seller', style: const TextStyle(fontSize: 24)),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    // Assume _isPremiumUser is available in SellerHomePage state
    final bool isPremiumUser = _isPremiumUser;

    final List<Widget> pages = [
      SellerDashboardTab(sellerId: user.uid, isPremiumUser: isPremiumUser),
      const RegisterProductScreen(),
      const ManageProductsScreen(),
      SellerOrderTrackingScreen(sellerId: user.uid),
      SellerChatsScreen(sellerId: user.uid),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 4,
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(kLogoUrl, width: 40, height: 40, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Text(
              kStoreName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
              accountName: Text(user.email ?? 'Seller'),
              accountEmail: Text(user.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Register Product'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Products'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chats'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SellerSupportScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Register'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        ],
      ),
    );
  }
}

class SellerDashboardTab extends StatelessWidget {
  final String sellerId;
  final bool isPremiumUser;
  const SellerDashboardTab({super.key, required this.sellerId, this.isPremiumUser = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerIds', arrayContains: sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading stats:  [${snapshot.error}'));
        }
        final orders = snapshot.data?.docs ?? [];
        // Gather all seller's items from all orders
        List<CartItem> allSellerItems = [];
        for (final doc in orders) {
          final order = app_order.Order.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          allSellerItems.addAll(order.items.where((item) => item.sellerId == sellerId));
        }
        // Stats
        final totalSales = allSellerItems.fold(0.0, (sum, item) => sum + item.totalPrice);
        final totalProductsSold = allSellerItems.fold(0, (sum, item) => sum + item.quantity);
        final totalOrders = orders.length;
        // Best-selling products
        final Map<String, int> productSales = {};
        final Map<String, String> productNames = {};
        for (final item in allSellerItems) {
          productSales[item.productId] = (productSales[item.productId] ?? 0) + item.quantity;
          productNames[item.productId] = item.name;
        }
        final bestSellers = productSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        // Recent orders
        final recentOrders = orders.take(5).map((doc) {
          final order = app_order.Order.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          final items = order.items.where((item) => item.sellerId == sellerId).toList();
          return {
            'order': order,
            'items': items,
          };
        }).toList();
        final now = DateTime.now();
        final salesPerDay = List<double>.filled(7, 0.0);
        for (final item in allSellerItems) {
          final orderDate = item.addedAt;
          final daysAgo = now.difference(orderDate).inDays;
          if (daysAgo >= 0 && daysAgo < 7) {
            salesPerDay[6 - daysAgo] += item.totalPrice;
          }
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Sales Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(title: 'Total Sales', value: '£${totalSales.toStringAsFixed(2)}', icon: Icons.attach_money),
                  _StatCard(title: 'Orders', value: '$totalOrders', icon: Icons.receipt_long),
                  _StatCard(title: 'Products Sold', value: '$totalProductsSold', icon: Icons.shopping_bag),
                ],
              ),
              const SizedBox(height: 32),
              if (isPremiumUser) ...[
                const Text('Premium Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 12),
                Card(
                  color: Colors.deepPurple[50],
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Conversion Rate: 12.5%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Average Order Value: £45.20', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Returning Customers: 8', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Top Region: London', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Premium analytics are only available to premium sellers.', style: TextStyle(fontSize: 14, color: Colors.deepPurple)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              const Text('Best-Selling Products (Top 5)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: bestSellers.isEmpty
                    ? const Center(child: Text('No sales data yet.'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: bestSellers.first.value.toDouble() * 1.2 + 1,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= bestSellers.length) return const SizedBox.shrink();
                                  final productId = bestSellers[idx].key;
                                  return Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      productNames[productId] ?? '',
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                                reservedSize: 60,
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            for (int i = 0; i < bestSellers.length && i < 5; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: bestSellers[i].value.toDouble(),
                                    color: const Color(0xFF6C63FF),
                                    width: 24,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              const Text('Sales (Last 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: salesPerDay.every((v) => v == 0)
                    ? const Center(child: Text('No sales data yet.'))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  return Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(days[value.toInt() % 7], style: TextStyle(fontSize: 12)),
                                  );
                                },
                                reservedSize: 32,
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          maxY: salesPerDay.reduce((a, b) => a > b ? a : b) * 1.2 + 1,
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < 7; i++) FlSpot(i.toDouble(), salesPerDay[i]),
                              ],
                              isCurved: true,
                              color: const Color(0xFF6C63FF),
                              barWidth: 4,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: const Color(0xFF6C63FF).withOpacity(0.15)),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (recentOrders.isEmpty)
                const Text('No recent orders.'),
              for (final entry in recentOrders)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('Order #${(entry['order'] as app_order.Order).id.substring(0, 8)}'),
                    subtitle: Text('Buyer: ${(entry['order'] as app_order.Order).userEmail}\nItems: ${(entry['items'] as List<CartItem>).length}'),
                    trailing: Text('£${(entry['items'] as List<CartItem>).fold(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2)}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF6C63FF)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
