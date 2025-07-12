import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Last 7 Days';
  final List<String> _periodOptions = ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'All Time'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text('Time Period: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      items: _periodOptions.map((period) {
                        return DropdownMenuItem(value: period, child: Text(period));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Key Metrics Cards
            _buildKeyMetricsSection(),
            const SizedBox(height: 24),

            // Sales Analytics
            _buildSalesAnalyticsSection(),
            const SizedBox(height: 24),

            // Customer Analytics
            _buildCustomerAnalyticsSection(),
            const SizedBox(height: 24),

            // Order Analytics
            _buildOrderAnalyticsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data!.docs;
            final totalRevenue = orders.fold<double>(
              0,
              (sum, doc) => sum + (doc.data() as Map<String, dynamic>)['total'],
            );
            final totalOrders = orders.length;
            final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard(
                  'Total Revenue',
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Avg Order Value',
                  '\$${avgOrderValue.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Active Products',
                  'Loading...',
                  Icons.inventory,
                  Colors.purple,
                  future: _getActiveProductsCount(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {Future<String>? future}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (future != null)
              FutureBuilder<String>(
                future: future,
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Loading...',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
                },
              )
            else
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesAnalyticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = snapshot.data!.docs;
                  final salesData = _getSalesData(orders);

                  return LineChart(
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
                              if (value.toInt() < salesData.length) {
                                return Text(salesData[value.toInt()]['date']);
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: salesData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value['revenue']);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerAnalyticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;
                final totalCustomers = users.length;
                final newCustomers = users.where((user) {
                  final data = user.data() as Map<String, dynamic>;
                  final createdAt = data['createdAt'] as Timestamp?;
                  if (createdAt == null) return false;
                  final daysSinceCreation = DateTime.now().difference(createdAt.toDate()).inDays;
                  return daysSinceCreation <= 7;
                }).length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildCustomerMetricCard(
                        'Total Customers',
                        totalCustomers.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCustomerMetricCard(
                        'New Customers (7 days)',
                        newCustomers.toString(),
                        Icons.person_add,
                        Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }



  Widget _buildOrderAnalyticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = snapshot.data!.docs;
                  final statusData = _getOrderStatusData(orders);

                  return PieChart(
                    PieChartData(
                      sections: statusData.map((data) {
                        return PieChartSectionData(
                          value: data['count'].toDouble(),
                          title: '${data['status']}\n${data['count']}',
                          color: data['color'],
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: 40,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSalesData(List<QueryDocumentSnapshot> orders) {
    final Map<String, double> dailySales = {};
    
    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateStr = '${date.month}/${date.day}';
      final total = data['total'] as double;
      
      dailySales[dateStr] = (dailySales[dateStr] ?? 0) + total;
    }

    final sortedDates = dailySales.keys.toList()..sort();
    return sortedDates.map((date) => {
      'date': date,
      'revenue': dailySales[date]!,
    }).toList();
  }



  List<Map<String, dynamic>> _getOrderStatusData(List<QueryDocumentSnapshot> orders) {
    final Map<String, int> statusCounts = {};

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final statusColors = {
      'pending': Colors.orange,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };

    return statusCounts.entries.map((entry) => {
      'status': entry.key,
      'count': entry.value,
      'color': statusColors[entry.key] ?? Colors.grey,
    }).toList();
  }

  Future<String> _getActiveProductsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .get();
    return snapshot.docs.length.toString();
  }
} 