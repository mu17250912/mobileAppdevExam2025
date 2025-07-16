import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_dashboard.dart';
import 'finance_screen.dart';

class ExpandableCard extends StatefulWidget {
  final String title;
  final Widget child;
  final Color? titleColor;
  const ExpandableCard({
    Key? key,
    required this.title,
    required this.child,
    this.titleColor,
  }) : super(key: key);
  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.titleColor ?? Colors.black,
                fontSize: 18,
              ),
            ),
            trailing: GestureDetector(
              onTap: () => setState(() => expanded = !expanded),
              child: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Icon(
                  expanded ? Icons.remove : Icons.add,
                  color: expanded ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

Future<Map<String, String>> getUserInfo(String uid) async {
  if (uid.isEmpty) return {'name': '', 'email': ''};
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  final data = doc.data();
  return {'name': data?['name'] ?? '', 'email': data?['email'] ?? ''};
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  int _salesCount = 0;
  Map<String, int> _salesByMonth = {};
  Map<String, int> _topSellers = {};
  Map<String, int> _subjectDistribution = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _loading = true);
    final booksSnap = await FirebaseFirestore.instance
        .collection('books')
        .where('status', isEqualTo: 'sold')
        .get();
    final sales = booksSnap.docs;
    final now = DateTime.now();
    _salesByMonth.clear();
    _topSellers.clear();
    _subjectDistribution.clear();
    for (var doc in sales) {
      final data = doc.data() as Map<String, dynamic>;
      final soldAt = data['soldAt'] is Timestamp
          ? (data['soldAt'] as Timestamp).toDate()
          : null;
      if (soldAt != null) {
        final key = DateFormat('yyyy-MM').format(soldAt);
        _salesByMonth[key] = (_salesByMonth[key] ?? 0) + 1;
      }
      final seller = data['sellerId'] ?? '';
      if (seller.isNotEmpty) {
        _topSellers[seller] = (_topSellers[seller] ?? 0) + 1;
      }
      final subject = (data['subject'] ?? '').toString();
      if (subject.isNotEmpty) {
        _subjectDistribution[subject] =
            (_subjectDistribution[subject] ?? 0) + 1;
      }
    }
    setState(() {
      _salesCount = sales.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.black,
      ),
      drawer: _adminDrawer(context),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: SpinKitWave(color: Color(0xFF9CE800), size: 40))
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter chips for Today, This Week, This Month (UI only, logic to be added)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilterChip(
                          label: Text('Today'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          label: Text('This Week'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          label: Text('This Month'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Card(
                      elevation: 5,
                      color: Colors.white,
                      shadowColor: Colors.green.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: Colors.green,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatRWF(_salesCount),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sales',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ExpandableCard(
                      title: 'Sales by Month',
                      titleColor: Colors.green,
                      child: _barChart(
                        'Sales by Month',
                        _salesByMonth,
                        Colors.green,
                      ),
                    ),
                    ExpandableCard(
                      title: 'Top Sellers',
                      titleColor: Colors.blue,
                      child: Column(
                        children: _topSellers.entries.map((entry) {
                          return FutureBuilder<Map<String, String>>(
                            future: getUserInfo(entry.key),
                            builder: (context, snapshot) {
                              final info =
                                  snapshot.data ?? {'name': '', 'email': ''};
                              return ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  info['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(info['email'] ?? ''),
                                trailing: Text(
                                  '${entry.value} sales',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    ExpandableCard(
                      title: 'Book Subjects Distribution',
                      titleColor: Colors.deepPurple,
                      child: _pieChartWidget(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Card(
      elevation: 5,
      color: Colors.white,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 110,
        height: 90,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barChart(String title, Map<String, int> data, Color color) {
    final sortedKeys = data.keys.toList()..sort();
    final maxVal = data.values.isEmpty
        ? 1
        : data.values.reduce((a, b) => a > b ? a : b);
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: color.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sortedKeys.map((k) {
                  final v = data[k] ?? 0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 100 * (v / maxVal),
                          width: 18,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(k, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topSellersWidget() {
    final sorted = _topSellers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.blue.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Sellers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...sorted
                .take(5)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        CircleAvatar(child: Text(e.key[0].toUpperCase())),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Text(
                          '${e.value} sales',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _pieChartWidget() {
    if (_subjectDistribution.isEmpty) {
      return const Card(
        elevation: 4,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No subject data for pie chart.')),
        ),
      );
    }
    final total = _subjectDistribution.values.fold(0, (a, b) => a + b);
    final colors = [
      Colors.blue,
      Colors.deepPurple,
      Colors.green,
      Color(0xFF9CE800),
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.teal,
      Colors.brown,
      Colors.cyan,
    ];
    final entries = _subjectDistribution.entries.toList();
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.deepPurple.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Subjects Distribution',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final percent = (e.value / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      color: colors[i % colors.length],
                      value: e.value.toDouble(),
                      title: '${e.key}\n$percent%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Admin Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'BookSwap',
                  style: TextStyle(
                    color: Color(0xFF9CE800),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.black),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: const Text('Finance'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const FinanceScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Color(0xFF9CE800)),
            title: const Text('Reports'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

String formatRWF(num amount) => 'RWF ${amount.toStringAsFixed(0)}';
 