import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnalyticsService _analyticsService;
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  String _selectedPeriod = '30'; // days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _analyticsService = AnalyticsService();
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _getRealAnalyticsData();
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getRealAnalyticsData() async {
    final now = DateTime.now();
    final daysAgo = int.parse(_selectedPeriod);
    final startDate = now.subtract(Duration(days: daysAgo));

    // Get purchase requests data
    final requestsQuery = await FirebaseFirestore.instance
        .collection('purchase_requests')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    final requests = requestsQuery.docs;
    
    // Get users data
    final usersQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    final users = usersQuery.docs;

    // Calculate metrics
    final totalRequests = requests.length;
    final totalUsers = users.length;
    final paidRequests = requests.where((doc) {
      final data = doc.data();
      return data['paymentStatus'] == 'paid';
    }).length;
    final connectedRequests = requests.where((doc) {
      final data = doc.data();
      return data['status'] == 'connected';
    }).length;
    final totalRevenue = paidRequests * 50 + connectedRequests * 50;

    // Calculate daily trends
    final dailyData = <String, int>{};
    final dailyRevenue = <String, double>{};
    
    for (int i = 0; i < daysAgo; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr = '${date.day}/${date.month}';
      dailyData[dateStr] = 0;
      dailyRevenue[dateStr] = 0;
    }

    for (final doc in requests) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final dateStr = '${date.day}/${date.month}';
        dailyData[dateStr] = (dailyData[dateStr] ?? 0) + 1;
        
        if (data['paymentStatus'] == 'paid' || data['status'] == 'connected') {
          dailyRevenue[dateStr] = (dailyRevenue[dateStr] ?? 0) + 50;
        }
      }
    }

    return {
      'total_users': totalUsers,
      'total_requests': totalRequests,
      'total_revenue': totalRevenue.toDouble(),
      'paid_requests': paidRequests,
      'connected_requests': connectedRequests,
      'conversion_rate': totalRequests > 0 ? (paidRequests / totalRequests * 100) : 0.0,
      'daily_requests': dailyData,
      'daily_revenue': dailyRevenue,
      'top_properties': await _getTopProperties(),
      'recent_activity': await _getRecentActivity(),
    };
  }

  Future<List<Map<String, dynamic>>> _getTopProperties() async {
    final requestsQuery = await FirebaseFirestore.instance
        .collection('purchase_requests')
        .get();

    final requests = requestsQuery.docs;
    final propertyCounts = <String, int>{};

    for (final doc in requests) {
      final data = doc.data();
      final propertyTitle = data['propertyTitle'] ?? 'Unknown';
      propertyCounts[propertyTitle] = (propertyCounts[propertyTitle] ?? 0) + 1;
    }

    final sortedProperties = propertyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedProperties.take(5).map((entry) => {
      'title': entry.key,
      'requests': entry.value,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    final requestsQuery = await FirebaseFirestore.instance
        .collection('purchase_requests')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    return requestsQuery.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'buyerName': data['buyerName'] ?? 'Unknown',
        'propertyTitle': data['propertyTitle'] ?? 'Unknown',
        'status': data['status'] ?? 'pending',
        'paymentStatus': data['paymentStatus'] ?? 'pending',
        'timestamp': data['timestamp'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Revenue'),
            Tab(text: 'Requests'),
            Tab(text: 'Activity'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadAnalyticsData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30', child: Text('Last 30 days')),
              const PopupMenuItem(value: '90', child: Text('Last 90 days')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRevenueTab(),
                _buildRequestsTab(),
                _buildActivityTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Users', _analyticsData['total_users'].toString(), Icons.people, AppColors.primary)),
              const SizedBox(width: AppSizes.sm),
              Expanded(child: _buildMetricCard('Total Requests', _analyticsData['total_requests'].toString(), Icons.receipt_long, AppColors.secondary)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Revenue', '\$${_analyticsData['total_revenue']}', Icons.attach_money, AppColors.success)),
              const SizedBox(width: AppSizes.sm),
              Expanded(child: _buildMetricCard('Conversion Rate', '${_analyticsData['conversion_rate'].toStringAsFixed(1)}%', Icons.trending_up, AppColors.info)),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // Revenue Chart
          _buildRevenueChart(),
          const SizedBox(height: AppSizes.lg),

          // Top Properties
          _buildTopPropertiesSection(),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    final dailyRevenue = _analyticsData['daily_revenue'] as Map<String, double>;
    final revenueData = dailyRevenue.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trends',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSizes.md),
          
          // Revenue Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('\$${value.toInt()}');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < revenueData.length) {
                          return Text(revenueData[value.toInt()].key);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: revenueData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    final dailyRequests = _analyticsData['daily_requests'] as Map<String, int>;
    final requestsData = dailyRequests.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Trends',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSizes.md),
          
          // Requests Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: requestsData.fold(0, (max, entry) => entry.value > max ? entry.value : max).toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < requestsData.length) {
                          return Text(requestsData[value.toInt()].key);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                barGroups: requestsData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: AppColors.secondary,
                        width: 20,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final recentActivity = _analyticsData['recent_activity'] as List<Map<String, dynamic>>;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: recentActivity.length,
      itemBuilder: (context, index) {
        final activity = recentActivity[index];
        final timestamp = activity['timestamp'] as Timestamp?;
        final timeAgo = timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Unknown';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(activity['status']).withOpacity(0.1),
              child: Icon(
                _getStatusIcon(activity['status']),
                color: _getStatusColor(activity['status']),
              ),
            ),
            title: Text(
              '${activity['buyerName']} requested ${activity['propertyTitle']}',
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Status: ${activity['status']} • Payment: ${activity['paymentStatus']}',
              style: AppTextStyles.caption,
            ),
            trailing: Text(
              timeAgo,
              style: AppTextStyles.caption.copyWith(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSizes.xs),
            Text(
              value,
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final dailyRevenue = _analyticsData['daily_revenue'] as Map<String, double>;
    final revenueData = dailyRevenue.entries.toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Revenue',
            style: AppTextStyles.heading5.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.md),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('\$${value.toInt()}');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < revenueData.length) {
                          return Text(revenueData[value.toInt()].key);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: revenueData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPropertiesSection() {
    final topProperties = _analyticsData['top_properties'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Properties',
            style: AppTextStyles.heading5.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.md),
          ...topProperties.map((property) => ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                '${property['requests']}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(property['title']),
            subtitle: Text('${property['requests']} requests'),
          )),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'connected':
        return AppColors.success;
      case 'paid':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'connected':
        return Icons.check_circle;
      case 'paid':
        return Icons.payment;
      default:
        return Icons.pending;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 