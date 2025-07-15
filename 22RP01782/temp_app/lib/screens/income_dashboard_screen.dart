// lib/screens/income_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class IncomeDashboardScreen extends StatefulWidget {
  const IncomeDashboardScreen({super.key});

  @override
  State<IncomeDashboardScreen> createState() => _IncomeDashboardScreenState();
}

class _IncomeDashboardScreenState extends State<IncomeDashboardScreen> {
  bool _isLoading = true;
  bool _isPremium = false;
  double _totalIncome = 0.0;
  List<Map<String, dynamic>> _incomeEntries = [];
  Map<String, double> _categoryTotals = {};
  List<Map<String, dynamic>> _earningsByDate = [];

  // Define better colors for the pie chart
  final List<Color> _chartColors = [
    const Color(0xFF6A4C93), // Deep Purple
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFFE91E63), // Pink
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF009688), // Teal
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFF795548), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final premium = userDoc.data()?['premium'] ?? false;

    if (!premium) {
      setState(() {
        _isPremium = false;
        _isLoading = false;
      });
      return;
    }

    // Load completed gigs from applications
    final appsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('applications')
        .where('status', isEqualTo: 'completed')
        .get();

    // Load manual income entries
    final manualIncomeSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('income')
        .orderBy('timestamp', descending: true)
        .get();

    double total = 0;
    Map<String, double> categoryTotals = {};
    Map<String, double> dateTotals = {};
    List<Map<String, dynamic>> entries = [];

    // Add completed gigs
    for (var doc in appsSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
      final jobId = data['jobId'];
      // Fetch job details for category
      String category = 'Other';
      if (jobId != null) {
        final jobSnap = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
        if (jobSnap.exists) {
          category = jobSnap.data()?['category'] ?? 'Other';
        }
      }
      total += amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      if (completedAt != null) {
        final dateStr = '${completedAt.year}-${completedAt.month}-${completedAt.day}';
        dateTotals[dateStr] = (dateTotals[dateStr] ?? 0) + amount;
        entries.add({
          'amount': amount, 
          'date': completedAt, 
          'category': category, 
          'type': 'Gig',
          'jobId': jobId
        });
      }
    }

    // Add manual income entries
    for (var doc in manualIncomeSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      total += amount;
      categoryTotals['Manual'] = (categoryTotals['Manual'] ?? 0) + amount;
      if (timestamp != null) {
        final dateStr = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
        dateTotals[dateStr] = (dateTotals[dateStr] ?? 0) + amount;
        entries.add({
          'amount': amount, 
          'date': timestamp, 
          'category': 'Manual', 
          'type': 'Manual',
          'docId': doc.id
        });
      }
    }

    // Sort entries by date descending
    entries.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Sort earnings by date
    final sortedDates = dateTotals.keys.toList()..sort();
    List<Map<String, dynamic>> earningsByDate = [
      for (final d in sortedDates)
        {'date': d, 'amount': dateTotals[d]}
    ];

    setState(() {
      _isPremium = true;
      _totalIncome = total;
      _incomeEntries = entries;
      _categoryTotals = categoryTotals;
      _earningsByDate = earningsByDate;
      _isLoading = false;
    });
  }

  void _addIncome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final amount = await showDialog<double>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Income'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter amount'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                Navigator.pop(context, value);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (amount != null && amount > 0) {
      final entry = {
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('income')
          .add(entry);

      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Income Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Income Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Premium required to access Income Dashboard.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/premium'),
                child: const Text('Get Premium Access'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Income Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Income Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Total Income',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Charts Section
            if (_earningsByDate.isNotEmpty) ...[
              const Text(
                'Earnings Over Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
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
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _earningsByDate.length) return const SizedBox();
                              final date = _earningsByDate[idx]['date'];
                              final parts = date.toString().split('-');
                              if (parts.length >= 3) {
                                return Text('${parts[1]}/${parts[2]}');
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < _earningsByDate.length; i++)
                              FlSpot(i.toDouble(), (_earningsByDate[i]['amount'] as double?) ?? 0),
                          ],
                          isCurved: true,
                          color: Colors.deepPurple,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.deepPurple,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.deepPurple.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Pie Chart Section
            if (_categoryTotals.isNotEmpty) ...[
              const Text(
                'Income by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PieChart(
                    PieChartData(
                      sections: [
                        for (int i = 0; i < _categoryTotals.entries.length; i++)
                          PieChartSectionData(
                            value: _categoryTotals.entries.elementAt(i).value,
                            title: '${_categoryTotals.entries.elementAt(i).key}\n\$${_categoryTotals.entries.elementAt(i).value.toStringAsFixed(0)}',
                            color: _chartColors[i % _chartColors.length],
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Income Entries Section
            const Text(
              'Income History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_incomeEntries.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No income entries yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete gigs or add manual income to see your earnings',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _incomeEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _incomeEntries[index];
                    final date = entry['date'] as DateTime?;
                    final isManual = entry['type'] == 'Manual';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isManual ? Icons.attach_money : Icons.work,
                          color: Colors.deepPurple,
                        ),
                        title: Text(
                          isManual ? 'Manual Income' : 'Gig Income',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${entry['category']} • ${date != null ? '${date.month}/${date.day}/${date.year}' : 'Unknown date'}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${entry['amount'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (isManual && entry['docId'] != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                    onPressed: () => _editIncome(entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                    onPressed: () => _deleteIncome(entry),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 80), // Add bottom padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addIncome,
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
    );
  }

  Future<void> _editIncome(Map<String, dynamic> entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || entry['docId'] == null) return;

    final amountController = TextEditingController(text: entry['amount'].toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Income'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newAmount = double.tryParse(amountController.text.trim());
      if (newAmount != null && newAmount > 0) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('income')
            .doc(entry['docId'])
            .update({'amount': newAmount});
        _loadData();
      }
    }
  }

  Future<void> _deleteIncome(Map<String, dynamic> entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || entry['docId'] == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text('Are you sure you want to delete this income entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('income')
          .doc(entry['docId'])
          .delete();
      _loadData();
    }
  }
}
