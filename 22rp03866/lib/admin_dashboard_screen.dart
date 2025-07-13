import 'package:flutter/material.dart';
import 'admin_sidebar.dart';
import 'admin_booking_management_screen.dart';
import 'admin_park_management_screen.dart';
import 'admin_user_management_screen.dart';
import 'theme/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return _DashboardContent(); // Dashboard overview
      case 1:
        return AdminBookingManagementScreen(); // Bookings management
      case 2:
        return AdminParkManagementScreen(); // Parks management
      case 3:
        return AdminUserManagementScreen(); // Users management
      case 4:
        // Logout logic
        // Example:
        // await FirebaseAuth.instance.signOut();
        // Navigator.of(context).pushReplacementNamed('/'); // or your login screen
        return Center(child: Text('Logging out...', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)));
      default:
        return _DashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: _getScreen(_selectedIndex),
          ),
        ],
      ),
    );
  }
}

// Replace this with your actual dashboard content widget
class _DashboardContent extends StatefulWidget {
  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<List<int>> _fetchParkBookingsPerMonth() async {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    final counts = List<int>.filled(6, 0);
    final start = DateTime(months.first.year, months.first.month, 1);
    final end = DateTime(months.last.year, months.last.month + 1, 0, 23, 59, 59);
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final ts = data['timestamp'];
      if (ts is Timestamp) {
        final dt = ts.toDate();
        for (int i = 0; i < months.length; i++) {
          if (dt.year == months[i].year && dt.month == months[i].month) {
            counts[i]++;
            break;
          }
        }
      }
    }
    return counts;
  }

  Future<Map<String, int>> _fetchBookingStatusCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('bookings').get();
    int confirmed = 0, completed = 0, cancelled = 0, all = snapshot.docs.length;
    for (var doc in snapshot.docs) {
      final status = doc['status'] ?? '';
      if (status == 'Confirmed') {
        confirmed++;
      } else if (status == 'Completed') completed++;
      else if (status == 'Cancelled') cancelled++;
    }
    return {
      'Confirmed': confirmed,
      'Completed': completed,
      'Cancelled': cancelled,
      'All': all,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 24),
              // Responsive metrics row
              isWide
                  ? Row(
                      children: [
                        Expanded(child: _MetricCard(title: 'Total Bookings', value: '1,247', color: AppColors.primary)),
                        SizedBox(width: 16),
                        Expanded(child: _MetricCard(title: 'Total Revenue', value: '\u0024 45,890', color: AppColors.accent)),
                        SizedBox(width: 16),
                        Expanded(child: _MetricCard(title: 'Active Parks', value: '8', color: AppColors.secondary)),
                      ],
                    )
                  : Column(
                      children: [
                        _MetricCard(title: 'Total Bookings', value: '1,247', color: AppColors.primary),
                        SizedBox(height: 12),
                        _MetricCard(title: 'Total Revenue', value: '\u0024 45,890', color: AppColors.accent),
                        SizedBox(height: 12),
                        _MetricCard(title: 'Active Parks', value: '8', color: AppColors.secondary),
                      ],
                    ),
              const SizedBox(height: 32),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Analytics Chart
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 260,
                            margin: EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Park Bookings Over Time', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                                  SizedBox(height: 12),
                                  Expanded(
                                    child: FutureBuilder<List<int>>(
                                      future: _fetchParkBookingsPerMonth(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Center(child: CircularProgressIndicator(color: AppColors.primary));
                                        }
                                        if (snapshot.hasError) {
                                          return Center(child: Text('Error loading data'));
                                        }
                                        final data = snapshot.data ?? List<int>.filled(6, 0);
                                        return LineChart(
                                          LineChartData(
                                            gridData: FlGridData(show: false),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    final now = DateTime.now();
                                                    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
                                                    if (value < 0 || value > 5) return SizedBox.shrink();
                                                    final m = months[value.toInt()];
                                                    return Text('${m.month}/${m.year % 100}', style: TextStyle(fontSize: 10));
                                                  },
                                                  interval: 1,
                                                ),
                                              ),
                                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            ),
                                            borderData: FlBorderData(show: false),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: List.generate(6, (i) => FlSpot(i.toDouble(), data[i].toDouble())),
                                                isCurved: true,
                                                color: AppColors.primary,
                                                barWidth: 4,
                                                dotData: FlDotData(show: false),
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
                          ),
                        ),
                        // Pie Chart Widget
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 260,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                                  SizedBox(height: 12),
                                  Expanded(
                                    child: FutureBuilder<Map<String, int>>(
                                      future: _fetchBookingStatusCounts(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Center(child: CircularProgressIndicator(color: AppColors.primary));
                                        }
                                        if (snapshot.hasError || !snapshot.hasData) {
                                          return Center(child: Text('Error loading data'));
                                        }
                                        final data = snapshot.data!;
                                        final total = data['All'] ?? 1;
                                        return PieChart(
                                          PieChartData(
                                            sections: [
                                              PieChartSectionData(
                                                color: AppColors.primary,
                                                value: data['Confirmed']?.toDouble() ?? 0,
                                                title: 'Confirmed',
                                                radius: 40,
                                                titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                                              ),
                                              PieChartSectionData(
                                                color: AppColors.success,
                                                value: data['Completed']?.toDouble() ?? 0,
                                                title: 'Completed',
                                                radius: 40,
                                                titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                                              ),
                                              PieChartSectionData(
                                                color: AppColors.danger,
                                                value: data['Cancelled']?.toDouble() ?? 0,
                                                title: 'Cancelled',
                                                radius: 40,
                                                titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                                              ),
                                            ],
                                            sectionsSpace: 2,
                                            centerSpaceRadius: 24,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Analytics Chart
                        Container(
                          height: 260,
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Park Bookings Over Time', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                                SizedBox(height: 12),
                                Expanded(
                                  child: FutureBuilder<List<int>>(
                                    future: _fetchParkBookingsPerMonth(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator(color: AppColors.primary));
                                      }
                                      if (snapshot.hasError) {
                                        return Center(child: Text('Error loading data'));
                                      }
                                      final data = snapshot.data ?? List<int>.filled(6, 0);
                                      return LineChart(
                                        LineChartData(
                                          gridData: FlGridData(show: false),
                                          titlesData: FlTitlesData(
                                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, meta) {
                                                  final now = DateTime.now();
                                                  final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
                                                  if (value < 0 || value > 5) return SizedBox.shrink();
                                                  final m = months[value.toInt()];
                                                  return Text('${m.month}/${m.year % 100}', style: TextStyle(fontSize: 10));
                                                },
                                                interval: 1,
                                              ),
                                            ),
                                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: List.generate(6, (i) => FlSpot(i.toDouble(), data[i].toDouble())),
                                              isCurved: true,
                                              color: AppColors.primary,
                                              barWidth: 4,
                                              dotData: FlDotData(show: false),
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
                        ),
                        // Pie Chart Widget
                        Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Booking Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                                SizedBox(height: 12),
                                Expanded(
                                  child: FutureBuilder<Map<String, int>>(
                                    future: _fetchBookingStatusCounts(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator(color: AppColors.primary));
                                      }
                                      if (snapshot.hasError || !snapshot.hasData) {
                                        return Center(child: Text('Error loading data'));
                                      }
                                      final data = snapshot.data!;
                                      final total = data['All'] ?? 1;
                                      return PieChart(
                                        PieChartData(
                                          sections: [
                                            PieChartSectionData(
                                              color: AppColors.primary,
                                              value: data['Confirmed']?.toDouble() ?? 0,
                                              title: 'Confirmed',
                                              radius: 40,
                                              titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                                            ),
                                            PieChartSectionData(
                                              color: AppColors.success,
                                              value: data['Completed']?.toDouble() ?? 0,
                                              title: 'Completed',
                                              radius: 40,
                                              titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                                            ),
                                            PieChartSectionData(
                                              color: AppColors.danger,
                                              value: data['Cancelled']?.toDouble() ?? 0,
                                              title: 'Cancelled',
                                              radius: 40,
                                              titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                                            ),
                                          ],
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 24,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
              // Add more widgets for latest bookings, etc.
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _MetricCard({required this.title, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 16, color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }
} 