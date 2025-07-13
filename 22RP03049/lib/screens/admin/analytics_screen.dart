import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _fetchAnalytics() async {
    final bookingsSnap = await FirebaseFirestore.instance.collection('bookings').get();
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final busesSnap = await FirebaseFirestore.instance.collection('buses').get();
    final routesSnap = await FirebaseFirestore.instance.collection('routes').get();

    final bookings = bookingsSnap.docs;
    final users = usersSnap.docs;
    final buses = busesSnap.docs;
    final routes = routesSnap.docs;

    // Total bookings
    final totalBookings = bookings.length;
    // Total paid bookings
    final totalPaidBookings = bookings.where((b) => b['paymentStatus'] == 'paid').length;
    // Total users
    final totalUsers = users.length;

    // Most popular route (by bookings)
    Map<String, int> routeCounts = {};
    for (var b in bookings) {
      final routeId = b['routeId'];
      if (routeId != null) {
        routeCounts[routeId] = (routeCounts[routeId] ?? 0) + 1;
      }
    }
    String? mostPopularRouteId;
    int maxRouteCount = 0;
    routeCounts.forEach((id, count) {
      if (count > maxRouteCount) {
        mostPopularRouteId = id;
        maxRouteCount = count;
      }
    });
    QueryDocumentSnapshot<Map<String, dynamic>>? mostPopularRoute;
    try {
      mostPopularRoute = routes.firstWhere((r) => r.id == mostPopularRouteId);
    } catch (_) {
      mostPopularRoute = null;
    }

    // Most active bus (by bookings)
    Map<String, int> busCounts = {};
    for (var b in bookings) {
      final busId = b['busId'];
      if (busId != null) {
        busCounts[busId] = (busCounts[busId] ?? 0) + 1;
      }
    }
    String? mostActiveBusId;
    int maxBusCount = 0;
    busCounts.forEach((id, count) {
      if (count > maxBusCount) {
        mostActiveBusId = id;
        maxBusCount = count;
      }
    });
    QueryDocumentSnapshot<Map<String, dynamic>>? mostActiveBus;
    try {
      mostActiveBus = buses.firstWhere((b) => b.id == mostActiveBusId);
    } catch (_) {
      mostActiveBus = null;
    }

    // Recent bookings (latest 5)
    final recentBookings = List.from(bookings)
      ..sort((a, b) {
        final aTime = a['bookingTime'] is Timestamp ? a['bookingTime'].toDate() : DateTime.now();
        final bTime = b['bookingTime'] is Timestamp ? b['bookingTime'].toDate() : DateTime.now();
        return bTime.compareTo(aTime);
      });

    // Top 5 routes for bar chart
    final topRoutes = routeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5Routes = topRoutes.take(5).toList();
    final top5RouteLabels = top5Routes.map((e) {
      QueryDocumentSnapshot<Map<String, dynamic>>? route;
      try {
        route = routes.firstWhere((r) => r.id == e.key);
      } catch (_) {
        route = null;
      }
      return route != null ? '${route['from']}→${route['to']}' : e.key;
    }).toList();
    final top5RouteCounts = top5Routes.map((e) => e.value).toList();

    // Pie chart data for paid/unpaid
    final unpaidCount = totalBookings - totalPaidBookings;

    return {
      'totalBookings': totalBookings,
      'totalPaidBookings': totalPaidBookings,
      'totalUsers': totalUsers,
      'mostPopularRoute': mostPopularRoute,
      'mostPopularRouteCount': maxRouteCount,
      'mostActiveBus': mostActiveBus,
      'mostActiveBusCount': maxBusCount,
      'recentBookings': recentBookings.take(5).toList(),
      'routes': routes,
      'buses': buses,
      'top5RouteLabels': top5RouteLabels,
      'top5RouteCounts': top5RouteCounts,
      'paidCount': totalPaidBookings,
      'unpaidCount': unpaidCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAnalytics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bar chart for top 5 routes
                if (data['top5RouteLabels'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Top 5 Routes by Bookings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF003366),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (data['top5RouteCounts'] as List<int>).isNotEmpty ? ((data['top5RouteCounts'] as List<int>).reduce((a, b) => a > b ? a : b) + 2).toDouble() : 10,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12, color: Colors.black),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  reservedSize: 28,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= data['top5RouteLabels'].length) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        data['top5RouteLabels'][idx],
                                        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                  reservedSize: 44,
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 2),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(
                              data['top5RouteCounts'].length,
                              (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: (data['top5RouteCounts'][i] as int).toDouble(),
                                    color: Colors.blueAccent,
                                    width: 24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                // Pie chart for paid/unpaid bookings
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Paid vs Unpaid Bookings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF003366),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    height: 180,
                    width: 220,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: (data['paidCount'] as int).toDouble(),
                            color: Colors.green,
                            title: (data['paidCount'] as int) > 0 ? 'Paid' : '',
                            radius: 45,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          PieChartSectionData(
                            value: (data['unpaidCount'] as int).toDouble(),
                            color: Colors.red,
                            title: (data['unpaidCount'] as int) > 0 ? 'Unpaid' : '',
                            radius: 45,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _AnalyticsCard(
                      title: 'Total Bookings',
                      value: data['totalBookings'].toString(),
                      icon: Icons.confirmation_num,
                      color: Colors.blue,
                    ),
                    _AnalyticsCard(
                      title: 'Paid Bookings',
                      value: data['totalPaidBookings'].toString(),
                      icon: Icons.payment,
                      color: Colors.green,
                    ),
                    _AnalyticsCard(
                      title: 'Total Users',
                      value: data['totalUsers'].toString(),
                      icon: Icons.people,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (data['mostPopularRoute'] != null)
                  _AnalyticsCard(
                    title: 'Most Popular Route',
                    value: '${data['mostPopularRoute']['from']} → ${data['mostPopularRoute']['to']}\n(${data['mostPopularRouteCount']} bookings)',
                    icon: Icons.alt_route,
                    color: Colors.purple,
                  ),
                if (data['mostActiveBus'] != null)
                  _AnalyticsCard(
                    title: 'Most Active Bus',
                    value: '${data['mostActiveBus']['company']} - ${data['mostActiveBus']['plateNumber']}\n(${data['mostActiveBusCount']} bookings)',
                    icon: Icons.directions_bus,
                    color: Colors.teal,
                  ),
                const SizedBox(height: 24),
                const Text('Recent Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...data['recentBookings'].map<Widget>((b) {
                  QueryDocumentSnapshot<Map<String, dynamic>>? bus;
                  try {
                    bus = data['buses'].firstWhere((bus) => bus.id == b['busId']);
                  } catch (_) {
                    bus = null;
                  }
                  QueryDocumentSnapshot<Map<String, dynamic>>? route;
                  try {
                    route = data['routes'].firstWhere((route) => route.id == b['routeId']);
                  } catch (_) {
                    route = null;
                  }
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.confirmation_num),
                      title: Text('Ticket: ${b['ticketCode'] ?? ''}'),
                      subtitle: Text(
                        'User: ${b['userId'] ?? ''}\n'
                        'Bus: ${bus != null ? (bus['company'] + ' - ' + bus['plateNumber']) : b['busId']}\n'
                        'Route: ${route != null ? (route['from'] + ' → ' + route['to']) : b['routeId']}\n'
                        'Status: ${b['status'] ?? ''}\n'
                        'Payment: ${b['paymentStatus'] ?? ''}\n'
                        'Booked: ${b['bookingTime'] != null && b['bookingTime'] is Timestamp ? (b['bookingTime'] as Timestamp).toDate().toString() : ''}',
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _AnalyticsCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 