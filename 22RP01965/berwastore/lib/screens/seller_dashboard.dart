import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'add_product_screen.dart';
import 'manage_inventory_screen.dart';
import 'analytics_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import '../widgets/todays_overview.dart';
import 'login_screen.dart';
import 'premium_features_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'admin_commissions_screen.dart';

class PremiumSubscriptionCard extends StatefulWidget {
  const PremiumSubscriptionCard({Key? key}) : super(key: key);

  @override
  State<PremiumSubscriptionCard> createState() => _PremiumSubscriptionCardState();
}

class _PremiumSubscriptionCardState extends State<PremiumSubscriptionCard> {
  bool _loading = false;

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    try {
      // 1. Get current user and their Stripe customer ID
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final stripeCustomerId = userDoc['stripeCustomerId']; // Must be set in Firestore

      // 2. Call your Cloud Function to create the subscription
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('createSubscription').call({
        'customerId': stripeCustomerId,
        'priceId': 'price_abc123', // <-- Replace with your Stripe price ID
      });

      final clientSecret = result.data['clientSecret'];

      // 3. Show Stripe payment sheet
      // await Stripe.instance.initPaymentSheet(
      //   paymentSheetParameters: SetupPaymentSheetParameters(
      //     paymentIntentClientSecret: clientSecret,
      //     merchantDisplayName: 'BerwaStore',
      //   ),
      // );
      // await Stripe.instance.presentPaymentSheet();

      // 4. After payment, update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isPremium': true,
        'subscriptionType': 'monthly',
        'subscriptionDate': DateTime.now(),
        'subscriptionExpiryDate': DateTime.now().add(Duration(days: 30)),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription successful! Welcome to BerwaStore Premium.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BerwaStore Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            SizedBox(height: 8),
            Text('RWF 2,000/month', style: TextStyle(color: Colors.green, fontSize: 18)),
            SizedBox(height: 12),
            Text('• Unlimited product uploads'),
            Text('• Sales analytics'),
            Text('• Priority support'),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _subscribe,
                child: _loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Subscribe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Recurring monthly payment. Cancel anytime.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 16),
            // Optional: Feature comparison table
            DataTable(
              columns: [
                DataColumn(label: Text('Feature')),
                DataColumn(label: Text('Free')),
                DataColumn(label: Text('Premium')),
              ],
              rows: [
                DataRow(cells: [DataCell(Text('Product Upload Limit')), DataCell(Text('10')), DataCell(Text('Unlimited'))]),
                DataRow(cells: [DataCell(Text('Reports')), DataCell(Text('Basic')), DataCell(Text('Sales Analytics'))]),
                DataRow(cells: [DataCell(Text('Support')), DataCell(Text('Email only')), DataCell(Text('WhatsApp / Call'))]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedIndex = 0;
  // Remove any ad initialization, AdSize, and ad widgets from this file.

  @override
  void initState() {
    super.initState();
    // Only initialize ads on mobile platforms
    // Remove any ad initialization, AdSize, and ad widgets from this file.
  }

  @override
  void dispose() {
    // Remove any ad initialization, AdSize, and ad widgets from this file.
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.green[600],
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.store, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Seller Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Banner
                  Card(
                    color: Colors.amber[100],
                    margin: const EdgeInsets.only(bottom: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.star, color: Colors.orange[800], size: 36),
                      title: const Text('Upgrade to Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: const Text('Unlock unlimited products, full reports, and more!'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PremiumFeaturesScreen()),
                          );
                        },
                        child: const Text('Go Premium'),
                      ),
                    ),
                  ),
                  // My Shop header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'My Shop',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick Actions Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildQuickActionCard(
                        'Add Product',
                        Icons.add_shopping_cart,
                        Colors.blue,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen())),
                      ),
                      _buildQuickActionCard(
                        'Manage Inventory',
                        Icons.inventory,
                        Colors.orange,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageInventoryScreen())),
                      ),
                      _buildQuickActionCard(
                        'View Orders',
                        Icons.receipt_long,
                        Colors.green,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersScreen())),
                      ),
                      _buildQuickActionCard(
                        'Analytics',
                        Icons.analytics,
                        Colors.purple,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Today's Overview
                  const Text(
                    "Today's Overview",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('products').snapshots(),
                    builder: (context, productSnap) {
                      print('Products StreamBuilder state: ${productSnap.connectionState}, hasError: ${productSnap.hasError}, hasData: ${productSnap.hasData}');
                      if (productSnap.hasError) {
                        print('Products StreamBuilder error: ${productSnap.error}');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 32),
                              SizedBox(height: 8),
                              Text('Error loading products: ${productSnap.error}'),
                            ],
                          ),
                        );
                      }
                      int productCount = productSnap.hasData ? productSnap.data!.docs.length : 0;
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                        builder: (context, orderSnap) {
                          print('Orders StreamBuilder state: ${orderSnap.connectionState}, hasError: ${orderSnap.hasError}, hasData: ${orderSnap.hasData}');
                          if (orderSnap.hasError) {
                            print('Orders StreamBuilder error: ${orderSnap.error}');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 32),
                                  SizedBox(height: 8),
                                  Text('Error loading orders: ${orderSnap.error}'),
                                ],
                              ),
                            );
                          }
                          int orderCount = orderSnap.hasData ? orderSnap.data!.docs.length : 0;
                          double sales = 0;
                          if (orderSnap.hasData) {
                            for (var doc in orderSnap.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final total = double.tryParse(data['total']?.toString() ?? '0') ?? 0;
                              sales += total;
                            }
                          }
                          int views = 0; // Replace with actual views logic if available
                          return TodaysOverview(
                            products: productCount,
                            orders: orderCount,
                            sales: sales.toInt(),
                            views: views,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Admin Commissions Dashboard (only for admin users)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) return SizedBox.shrink();
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      if (data['role'] == 'admin') {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.admin_panel_settings),
                              label: const Text('View Commissions Dashboard'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminCommissionsScreen()),
                                );
                              },
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Bottom Navigation with Ad
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Remove any ad initialization, AdSize, and ad widgets from this file.
              BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onNavTap,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.green[600],
                unselectedItemColor: Colors.grey,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
                  BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
                  BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
