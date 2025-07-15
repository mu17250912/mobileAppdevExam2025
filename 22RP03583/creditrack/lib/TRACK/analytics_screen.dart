import 'package:flutter/material.dart';
import '../firestore_service.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analytics = await _firestoreService.getAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7B8AFF),
      appBar: AppBar(
        backgroundColor: Color(0xFF7B8AFF),
        elevation: 0,
        title: Text('Analytics', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildOverviewCards(),
                  _buildDetailedMetrics(),
                  _buildRecentActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Borrowers',
                  '${_analytics['totalBorrowers'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Active Loans',
                  '${_analytics['totalLoans'] ?? 0}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Loaned',
                  '\$${(_analytics['totalLoaned'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Total Collected',
                  '\$${(_analytics['totalCollected'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.payment,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    final outstandingAmount = (_analytics['outstandingAmount'] is num) ? _analytics['outstandingAmount'] ?? 0.0 : 0.0;
    final totalLoaned = (_analytics['totalLoaned'] is num) ? _analytics['totalLoaned'] ?? 0.0 : 0.0;
    final totalLoans = (_analytics['totalLoans'] is num) ? _analytics['totalLoans'] ?? 0 : 0;
    final totalBorrowers = (_analytics['totalBorrowers'] is num) ? _analytics['totalBorrowers'] ?? 0 : 0;
    final collectionRate = (totalLoaned > 0) ? ((totalLoaned - outstandingAmount) / totalLoaned * 100) : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          _buildProgressIndicator(
            'Collection Rate',
            collectionRate,
            Colors.green,
            '${collectionRate.toStringAsFixed(1)}%',
          ),
          SizedBox(height: 16),
          _buildProgressIndicator(
            'Outstanding Amount',
            (outstandingAmount > 0 && totalLoaned > 0) ? (outstandingAmount / totalLoaned * 100) : 0,
            Colors.red,
            '\$${outstandingAmount.toStringAsFixed(2)}',
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSmallMetric(
                  'Avg. Loan Size',
                  (totalLoaned > 0 && totalLoans > 0)
                      ? '\$${(totalLoaned / totalLoans).toStringAsFixed(2)}'
                      : '\$0.00',
                  Icons.analytics,
                ),
              ),
              Expanded(
                child: _buildSmallMetric(
                  'Borrowers per Loan',
                  (totalLoans > 0 && totalBorrowers > 0)
                      ? '${(totalLoans / totalBorrowers).toStringAsFixed(1)}'
                      : '0',
                  Icons.people_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double percentage, Color color, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              value,
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
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildSmallMetric(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF7B8AFF), size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildActivityItem(
            Icons.person_add,
            'New borrower added',
            'John Doe',
            '2 hours ago',
            Colors.green,
          ),
          _buildActivityItem(
            Icons.account_balance_wallet,
            'New loan created',
            '\$5,000',
            '1 day ago',
            Colors.blue,
          ),
          _buildActivityItem(
            Icons.payment,
            'Payment received',
            '\$500',
            '2 days ago',
            Colors.purple,
          ),
          _buildActivityItem(
            Icons.notification_important,
            'Payment reminder',
            'Due in 3 days',
            '3 days ago',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String subtitle, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
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
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Text(
          'Settings Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
} 