import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic> analyticsData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await AnalyticsService.getAnalyticsSummary();
      setState(() {
        analyticsData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildRevenueChart(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              analyticsData['period'] ?? 'Last 30 days',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Logins',
          analyticsData['totalLogins']?.toString() ?? '0',
          Icons.login,
          Colors.blue,
        ),
        _buildMetricCard(
          'Total Orders',
          analyticsData['totalOrders']?.toString() ?? '0',
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildMetricCard(
          'Subscriptions',
          analyticsData['totalSubscriptions']?.toString() ?? '0',
          Icons.card_membership,
          Colors.green,
        ),
        _buildMetricCard(
          'Revenue',
          'Rwf ${analyticsData['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
          Icons.attach_money,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
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

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueItem(
                    'Orders',
                    analyticsData['totalRevenue'] ?? 0.0,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRevenueItem(
                    'Subscriptions',
                    analyticsData['totalRevenue'] ?? 0.0,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String label, double amount, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            label == 'Orders' ? Icons.shopping_cart : Icons.card_membership,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rwf ${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('analytics')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading recent activity');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activities = snapshot.data?.docs ?? [];

                if (activities.isEmpty) {
                  return const Text('No recent activity');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index].data() as Map<String, dynamic>;
                    return _buildActivityItem(activity);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    String event = activity['event'] ?? '';
    String description = '';
    IconData icon = Icons.info;

    switch (event) {
      case 'user_login':
        description = 'User logged in via ${activity['method'] ?? 'unknown'}';
        icon = Icons.login;
        break;
      case 'order_placed':
        description = 'Order placed: Rwf ${(activity['totalAmount'] ?? 0).toStringAsFixed(0)}';
        icon = Icons.shopping_cart;
        break;
      case 'subscription_purchased':
        description = 'Subscription: ${activity['planName'] ?? 'Unknown'}';
        icon = Icons.card_membership;
        break;
      case 'product_view':
        description = 'Product viewed: ${activity['productName'] ?? 'Unknown'}';
        icon = Icons.visibility;
        break;
      default:
        description = 'Activity: $event';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: Icon(icon, color: Colors.green, size: 20),
      ),
      title: Text(description),
      subtitle: Text(
        activity['userEmail'] ?? 'Anonymous user',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        _formatTimestamp(activity['timestamp']),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
} 