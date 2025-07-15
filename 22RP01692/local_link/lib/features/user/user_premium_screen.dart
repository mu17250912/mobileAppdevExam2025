import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'freemium_model_screen.dart';
import '../payment/payment_screen.dart';
import '../../services/notification_service.dart';

class UserPremiumScreen extends StatefulWidget {
  const UserPremiumScreen({super.key});

  @override
  State<UserPremiumScreen> createState() => _UserPremiumScreenState();
}

class _UserPremiumScreenState extends State<UserPremiumScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> _premiumFeatures = [
    {
      'id': 'priority_booking',
      'name': 'Priority Booking',
      'description': 'Get priority booking slots and faster service',
      'price': 7500,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.priority_high,
      'color': Colors.orange,
      'category': 'booking',
    },
    {
      'id': 'unlimited_bookings',
      'name': 'Unlimited Bookings',
      'description': 'Remove monthly booking limits',
      'price': 12000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.all_inclusive,
      'color': Colors.blue,
      'category': 'booking',
    },
    {
      'id': 'premium_support',
      'name': 'Premium Support',
      'description': '24/7 priority customer support',
      'price': 10000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.support_agent,
      'color': Colors.green,
      'category': 'support',
    },
    {
      'id': 'advanced_analytics',
      'name': 'Advanced Analytics',
      'description': 'Detailed booking history and insights',
      'price': 8000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.analytics,
      'color': Colors.purple,
      'category': 'analytics',
    },
    {
      'id': 'custom_notifications',
      'name': 'Custom Notifications',
      'description': 'Personalized notification preferences',
      'price': 6000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.notifications_active,
      'color': Colors.red,
      'category': 'notifications',
    },
    {
      'id': 'booking_history',
      'name': 'Extended History',
      'description': 'Access to unlimited booking history',
      'price': 5000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.history,
      'color': Colors.indigo,
      'category': 'history',
    },
  ];

  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'id': 'basic_plus',
      'name': 'Basic Plus',
      'price': 15000,
      'currency': 'FRW',
      'duration': 'per month',
      'features': [
        'Priority booking slots',
        'Unlimited bookings',
        'Basic analytics',
        'Email support',
      ],
      'color': Colors.blue,
      'popular': false,
    },
    {
      'id': 'premium_user',
      'name': 'Premium User',
      'price': 30000,
      'currency': 'FRW',
      'duration': 'per month',
      'features': [
        'Everything in Basic Plus',
        '24/7 priority support',
        'Advanced analytics',
        'Custom notifications',
        'Extended booking history',
        'Exclusive deals',
      ],
      'color': Colors.purple,
      'popular': true,
    },
    {
      'id': 'vip_user',
      'name': 'VIP User',
      'price': 60000,
      'currency': 'FRW',
      'duration': 'per month',
      'features': [
        'Everything in Premium',
        'Personal account manager',
        'Exclusive service providers',
        'Custom service requests',
        'Priority scheduling',
        'Special discounts',
      ],
      'color': Colors.amber,
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to access premium features.')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Premium Features'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FreemiumModelScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Features'),
              Tab(text: 'Subscriptions'),
              Tab(text: 'My Purchases'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildFeaturesTab(),
            _buildSubscriptionsTab(),
            _buildPurchasesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final virtualBalance = (userData['virtualBalance'] ?? 0).toDouble();
              final activeFeatures = userData['activeFeatures'] as List<dynamic>? ?? [];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Premium Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            '${virtualBalance.toInt()} FRW',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Active Features: ${activeFeatures.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddBalanceDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Balance'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Features Grid
          const Text(
            'Premium Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _premiumFeatures.length,
            itemBuilder: (context, index) {
              final feature = _premiumFeatures[index];
              return _buildFeatureCard(feature);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Plans',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a plan that fits your needs',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),

          ..._subscriptionPlans.map((plan) => _buildSubscriptionCard(plan)).toList(),
        ],
      ),
    );
  }

  Widget _buildPurchasesTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey[100],
            child: const TabBar(
              tabs: [
                Tab(text: 'Feature Purchases'),
                Tab(text: 'Subscriptions'),
              ],
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFeaturePurchasesTab(),
                _buildSubscriptionsHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePurchasesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userPurchases')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('purchaseDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading purchases',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final purchases = snapshot.data?.docs ?? [];

        if (purchases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No feature purchases yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start exploring premium features!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Switch to features tab
                    DefaultTabController.of(context).animateTo(0);
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Browse Features'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final purchase = purchases[index].data() as Map<String, dynamic>;
            final itemName = purchase['itemName'] ?? '';
            final amount = purchase['amount'] ?? 0.0;
            final date = (purchase['purchaseDate'] as Timestamp?)?.toDate();
            final status = purchase['status'] ?? 'active';
            final duration = purchase['duration'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status == 'active' 
                      ? Colors.green.withOpacity(0.3) 
                      : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: status == 'active' 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    status == 'active' ? Icons.check_circle : Icons.schedule,
                    color: status == 'active' ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                title: Text(
                  itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (date != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'active' 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: status == 'active' ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (duration.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              duration,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${amount.toInt()} FRW',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Feature',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubscriptionsHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userSubscriptions')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading subscriptions',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final subscriptions = snapshot.data?.docs ?? [];

        if (subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.subscriptions_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No subscriptions yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscribe to a plan to get started!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Switch to subscriptions tab
                    DefaultTabController.of(context).animateTo(1);
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('View Plans'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = subscriptions[index].data() as Map<String, dynamic>;
            final planName = subscription['planName'] ?? '';
            final amount = subscription['amount'] ?? 0.0;
            final startDate = (subscription['startDate'] as Timestamp?)?.toDate();
            final endDate = (subscription['endDate'] as Timestamp?)?.toDate();
            final status = subscription['status'] ?? 'active';

            final isActive = endDate?.isAfter(DateTime.now()) ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive 
                      ? Colors.green.withOpacity(0.3) 
                      : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.star : Icons.star_border,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                title: Text(
                  planName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (startDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Started: ${DateFormat('MMM dd, yyyy').format(startDate)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    if (endDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expires: ${DateFormat('MMM dd, yyyy').format(endDate)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'EXPIRED',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SUBSCRIPTION',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${amount.toInt()} FRW',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    final name = feature['name'] as String;
    final description = feature['description'] as String;
    final price = feature['price'] as double;
    final currency = feature['currency'] as String;
    final icon = feature['icon'] as IconData;
    final color = feature['color'] as Color;
    final duration = feature['duration'] as String;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$currency ${price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              'Duration: $duration',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showFeaturePurchaseDialog(feature),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'Purchase',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> plan) {
    final name = plan['name'] as String;
    final price = plan['price'] as double;
    final duration = plan['duration'] as String;
    final features = plan['features'] as List<String>;
    final color = plan['color'] as Color;
    final isPopular = plan['popular'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPopular ? 8 : 2,
      child: Container(
        decoration: isPopular
            ? BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MOST POPULAR',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const Spacer(),
                  Icon(Icons.star, color: color, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${price.toInt()} FRW',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showSubscriptionDialog(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Subscribe',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBalanceDialog(BuildContext context) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Virtual Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add funds to your virtual balance for premium features.'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (FRW)',
                prefixText: '',
                hintText: '10000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount >= 100) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      amount: amount,
                      description: 'Add funds to virtual balance',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount (minimum 100 FRW)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Continue to Payment'),
          ),
        ],
      ),
    );
  }

  void _showFeaturePurchaseDialog(Map<String, dynamic> feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${feature['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to purchase:'),
            const SizedBox(height: 8),
            Text(
              feature['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(feature['description']),
            const SizedBox(height: 8),
            Text(
              'Price: ${feature['price'].toInt()} ${feature['currency']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Duration: ${feature['duration']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processFeaturePurchase(feature);
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscribe to ${plan['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to subscribe to:'),
            const SizedBox(height: 8),
            Text(
              plan['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Price: ${plan['price'].toInt()} ${plan['currency']} ${plan['duration']}'),
            const SizedBox(height: 8),
            const Text('This includes:'),
            ...plan['features'].map((feature) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processSubscription(plan);
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSubscriptionNotificationToProviders(String planName, double amount) async {
    try {
      // Get all providers
      final providersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .get();

      // Get user data for name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final userName = userData['name'] ?? userData['displayName'] ?? user!.email?.split('@')[0] ?? 'User';

      // Send notification to each provider
      for (final providerDoc in providersSnapshot.docs) {
        await NotificationService.sendSubscriptionNotification(
          providerId: providerDoc.id,
          userId: user!.uid,
          userName: userName,
          planName: planName,
          amount: amount,
        );
      }
    } catch (e) {
      print('Error sending subscription notifications to providers: $e');
    }
  }

  Future<void> _addVirtualBalance(double amount) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'virtualBalance': FieldValue.increment(amount),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ${amount.toInt()} FRW to your balance'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding balance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processFeaturePurchase(Map<String, dynamic> feature) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final currentBalance = (userData['virtualBalance'] ?? 0).toDouble();
      final featurePrice = feature['price'] as double;

      if (currentBalance < featurePrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient balance. Please add more funds.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Deduct balance
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'virtualBalance': FieldValue.increment(-featurePrice),
      });

      // Add feature to user's active features
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'activeFeatures': FieldValue.arrayUnion([feature['id']]),
      });

      // Record purchase
      await FirebaseFirestore.instance
          .collection('userPurchases')
          .add({
        'userId': user!.uid,
        'itemId': feature['id'],
        'itemName': feature['name'],
        'amount': featurePrice,
        'currency': feature['currency'],
        'purchaseDate': FieldValue.serverTimestamp(),
        'duration': feature['duration'],
        'status': 'active',
      });

      // Send notification to all providers about the purchase
      await _sendPurchaseNotificationToProviders(feature['name'], featurePrice);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased ${feature['name']}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing purchase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendPurchaseNotificationToProviders(String featureName, double amount) async {
    try {
      // Get all providers
      final providersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .get();

      // Get user data for name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final userName = userData['name'] ?? userData['displayName'] ?? user!.email?.split('@')[0] ?? 'User';

      // Send notification to each provider
      for (final providerDoc in providersSnapshot.docs) {
        await NotificationService.sendPremiumPurchaseNotification(
          providerId: providerDoc.id,
          userId: user!.uid,
          userName: userName,
          featureName: featureName,
          amount: amount,
        );
      }
    } catch (e) {
      print('Error sending purchase notifications to providers: $e');
    }
  }

  Future<void> _processSubscription(Map<String, dynamic> plan) async {
    try {
      // Update user subscription
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'subscriptionPlan': plan['id'],
        'subscriptionExpiry': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'subscriptionDate': FieldValue.serverTimestamp(),
      });

      // Record subscription
      await FirebaseFirestore.instance
          .collection('userSubscriptions')
          .add({
        'userId': user!.uid,
        'planId': plan['id'],
        'planName': plan['name'],
        'amount': plan['price'],
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'status': 'active',
      });

      // Send notification to all providers about the subscription
      await _sendSubscriptionNotificationToProviders(plan['name'], plan['price']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully subscribed to ${plan['name']}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 