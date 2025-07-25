import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'user_premium_screen.dart';
import '../payment/payment_screen.dart';
import '../../services/notification_service.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to access dashboard.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserPremiumScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final virtualBalance = (userData['virtualBalance'] ?? 0).toDouble();
          final activeFeatures = userData['activeFeatures'] as List<dynamic>? ?? [];
          final subscriptionPlan = userData['subscriptionPlan'] as String?;
          final subscriptionExpiry = userData['subscriptionExpiry'] as Timestamp?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                _buildWelcomeSection(userData),
                const SizedBox(height: 24),

                // Premium Status Card
                _buildPremiumStatusCard(
                  virtualBalance,
                  activeFeatures,
                  subscriptionPlan,
                  subscriptionExpiry,
                ),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 24),

                // Active Features
                if (activeFeatures.isNotEmpty) ...[
                  _buildActiveFeatures(activeFeatures),
                  const SizedBox(height: 24),
                ],

                // Recent Activity
                _buildRecentActivity(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(Map<String, dynamic> userData) {
    final displayName = userData['displayName'] ?? user!.email?.split('@')[0] ?? 'User';
    final email = userData['email'] ?? user!.email ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green[100],
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $displayName!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStatusCard(
    double virtualBalance,
    List<dynamic> activeFeatures,
    String? subscriptionPlan,
    Timestamp? subscriptionExpiry,
  ) {
    final hasSubscription = subscriptionPlan != null && subscriptionExpiry != null;
    final isSubscriptionActive = hasSubscription && 
        subscriptionExpiry!.toDate().isAfter(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSubscriptionActive ? Icons.star : Icons.star_border,
                  color: isSubscriptionActive ? Colors.amber : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Premium Status',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSubscriptionActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSubscriptionActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Virtual Balance
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Virtual Balance:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  '${virtualBalance.toInt()} FRW',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subscription Info
            if (hasSubscription) ...[
              Row(
                children: [
                  Icon(Icons.subscriptions, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Plan:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    _getPlanDisplayName(subscriptionPlan!),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Expires:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(subscriptionExpiry!.toDate()),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'No active subscription',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Action Buttons
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
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserPremiumScreen()),
                      );
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Upgrade'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionCard(
              'Priority Booking',
              Icons.priority_high,
              Colors.orange,
              () => _showFeatureInfo('Priority booking slots and faster service'),
            ),
            _buildQuickActionCard(
              'Unlimited Bookings',
              Icons.all_inclusive,
              Colors.blue,
              () => _showFeatureInfo('Remove monthly booking limits'),
            ),
            _buildQuickActionCard(
              'Premium Support',
              Icons.support_agent,
              Colors.green,
              () => _showFeatureInfo('24/7 priority customer support'),
            ),
            _buildQuickActionCard(
              'Advanced Analytics',
              Icons.analytics,
              Colors.purple,
              () => _showFeatureInfo('Detailed booking history and insights'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveFeatures(List<dynamic> activeFeatures) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Features',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...activeFeatures.map((featureId) => _buildActiveFeatureCard(featureId)).toList(),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('userPurchases')
              .where('userId', isEqualTo: user!.uid)
              .orderBy('purchaseDate', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final purchases = snapshot.data!.docs;

            if (purchases.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent activity'),
                ),
              );
            }

            return Column(
              children: purchases.map((doc) {
                final purchase = doc.data() as Map<String, dynamic>;
                final itemName = purchase['itemName'] ?? '';
                final amount = purchase['amount'] ?? 0.0;
                final date = (purchase['purchaseDate'] as Timestamp?)?.toDate();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                    title: Text(itemName),
                    subtitle: date != null ? Text(DateFormat('MMM dd, yyyy').format(date)) : null,
                    trailing: Text(
                      '${amount.toInt()} FRW',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFeatureCard(String featureId) {
    final featureInfo = _getFeatureInfo(featureId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: featureInfo['color'].withOpacity(0.1),
          child: Icon(featureInfo['icon'], color: featureInfo['color']),
        ),
        title: Text(featureInfo['name']),
        subtitle: Text(featureInfo['description']),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'ACTIVE',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

  void _showFeatureInfo(String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserPremiumScreen()),
              );
            },
            child: const Text('Get Premium'),
          ),
        ],
      ),
    );
  }

  Future<void> _addVirtualBalance(double amount) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'virtualBalance': FieldValue.increment(amount),
      });

      // Send notification to all providers about balance addition
      await _sendBalanceNotification(amount);

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

  Future<void> _sendBalanceNotification(double amount) async {
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
        await NotificationService.sendBalanceAddedNotification(
          providerId: providerDoc.id,
          userId: user!.uid,
          userName: userName,
          amount: amount,
        );
      }
    } catch (e) {
      print('Error sending balance notifications to providers: $e');
    }
  }

  String _getPlanDisplayName(String planId) {
    switch (planId) {
      case 'basic_plus':
        return 'Basic Plus';
      case 'premium_user':
        return 'Premium User';
      case 'vip_user':
        return 'VIP User';
      default:
        return planId;
    }
  }

  Map<String, dynamic> _getFeatureInfo(String featureId) {
    switch (featureId) {
      case 'priority_booking':
        return {
          'name': 'Priority Booking',
          'description': 'Get priority booking slots and faster service',
          'icon': Icons.priority_high,
          'color': Colors.orange,
        };
      case 'unlimited_bookings':
        return {
          'name': 'Unlimited Bookings',
          'description': 'Remove monthly booking limits',
          'icon': Icons.all_inclusive,
          'color': Colors.blue,
        };
      case 'premium_support':
        return {
          'name': 'Premium Support',
          'description': '24/7 priority customer support',
          'icon': Icons.support_agent,
          'color': Colors.green,
        };
      case 'advanced_analytics':
        return {
          'name': 'Advanced Analytics',
          'description': 'Detailed booking history and insights',
          'icon': Icons.analytics,
          'color': Colors.purple,
        };
      case 'custom_notifications':
        return {
          'name': 'Custom Notifications',
          'description': 'Personalized notification preferences',
          'icon': Icons.notifications_active,
          'color': Colors.red,
        };
      case 'booking_history':
        return {
          'name': 'Extended History',
          'description': 'Access to unlimited booking history',
          'icon': Icons.history,
          'color': Colors.indigo,
        };
      default:
        return {
          'name': featureId,
          'description': 'Premium feature',
          'icon': Icons.star,
          'color': Colors.grey,
        };
    }
  }
} 