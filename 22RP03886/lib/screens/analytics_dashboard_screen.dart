import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/user_provider.dart';
import '../providers/subscription_provider.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  @override
  _AnalyticsDashboardScreenState createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
      analyticsProvider.trackScreenView(screenName: 'analytics_dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Consumer3<AnalyticsProvider, UserProvider, SubscriptionProvider>(
        builder: (context, analyticsProvider, userProvider, subscriptionProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Analytics Overview',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Track user behavior and revenue metrics',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),

                // User Metrics
                _buildMetricsSection(
                  title: 'User Metrics',
                  metrics: [
                    _buildMetricCard(
                      title: 'Total Users',
                      value: '1,234',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    _buildMetricCard(
                      title: 'Active Users',
                      value: '892',
                      icon: Icons.person,
                      color: Colors.green,
                    ),
                    _buildMetricCard(
                      title: 'Premium Users',
                      value: '156',
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                    _buildMetricCard(
                      title: 'Conversion Rate',
                      value: '12.6%',
                      icon: Icons.trending_up,
                      color: Colors.purple,
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Revenue Metrics
                _buildMetricsSection(
                  title: 'Revenue Metrics',
                  metrics: [
                    _buildMetricCard(
                      title: 'Monthly Revenue',
                      value: '\$2,450',
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    _buildMetricCard(
                      title: 'Annual Revenue',
                      value: '\$29,400',
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),
                    _buildMetricCard(
                      title: 'Avg. Revenue/User',
                      value: '\$19.80',
                      icon: Icons.analytics,
                      color: Colors.orange,
                    ),
                    _buildMetricCard(
                      title: 'Churn Rate',
                      value: '3.2%',
                      icon: Icons.trending_down,
                      color: Colors.red,
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Feature Usage
                _buildFeatureUsageSection(),

                SizedBox(height: 24),

                // Subscription Analytics
                _buildSubscriptionAnalyticsSection(subscriptionProvider),

                SizedBox(height: 24),

                // User Engagement
                _buildUserEngagementSection(),

                SizedBox(height: 24),

                // Recent Events
                _buildRecentEventsSection(),

                SizedBox(height: 32),

                // Analytics Actions
                _buildAnalyticsActionsSection(analyticsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsSection({
    required String title,
    required List<Widget> metrics,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: metrics,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              Icon(Icons.more_vert, color: Colors.grey[400], size: 16),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureUsageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Usage',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFeatureUsageItem('Task Creation', 85, Colors.blue),
              SizedBox(height: 12),
              _buildFeatureUsageItem('Note Taking', 72, Colors.green),
              SizedBox(height: 12),
              _buildFeatureUsageItem('Calendar Sync', 45, Colors.orange),
              SizedBox(height: 12),
              _buildFeatureUsageItem('Data Export', 28, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureUsageItem(String feature, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            Spacer(),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildSubscriptionAnalyticsSection(SubscriptionProvider subscriptionProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSubscriptionMetric('Monthly Subscriptions', '89', Colors.blue),
              SizedBox(height: 16),
              _buildSubscriptionMetric('Annual Subscriptions', '67', Colors.green),
              SizedBox(height: 16),
              _buildSubscriptionMetric('Active Subscriptions', '156', Colors.amber),
              SizedBox(height: 16),
              _buildSubscriptionMetric('Expired Subscriptions', '23', Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionMetric(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUserEngagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Engagement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildEngagementItem('Daily Active Users', '234', '+12%'),
              _buildEngagementItem('Weekly Active Users', '892', '+8%'),
              _buildEngagementItem('Monthly Active Users', '1,234', '+15%'),
              _buildEngagementItem('Session Duration', '4.2 min', '+5%'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementItem(String label, String value, String change) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildEventItem('New subscription', 'Monthly Pro', '2 min ago', Colors.green),
              _buildEventItem('Task completed', 'Work', '5 min ago', Colors.blue),
              _buildEventItem('Note created', 'Meeting notes', '12 min ago', Colors.orange),
              _buildEventItem('User registered', 'john@example.com', '1 hour ago', Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(String event, String details, String time, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsActionsSection(AnalyticsProvider analyticsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  analyticsProvider.trackCustomEvent(
                    eventName: 'analytics_export',
                    parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch as Object},
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Analytics data exported')),
                  );
                },
                icon: Icon(Icons.download),
                label: Text('Export Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  analyticsProvider.trackCustomEvent(
                    eventName: 'analytics_refresh',
                    parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch as Object},
                  );
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Analytics refreshed')),
                  );
                },
                icon: Icon(Icons.refresh),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 