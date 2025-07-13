import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_screen.dart';
import 'premium_features_summary.dart';

class ReportScreen extends StatefulWidget {
  final void Function(int)? onRequirePremium;
  const ReportScreen({super.key, this.onRequirePremium});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _searchQuery = '';
  bool _isPremium = false;
  final PremiumFeaturesManager _premiumManager = PremiumFeaturesManager();

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await _premiumManager.isPremium();
    setState(() {
      _isPremium = isPremium;
    });
  }

  Future<Map<String, dynamic>> _fetchReportData() async {
    final incomeSnap = await FirebaseFirestore.instance.collection('income').get();
    final expenseSnap = await FirebaseFirestore.instance.collection('expenses').get();
    num totalIncome = 0;
    num totalExpense = 0;
    Map<String, num> expenseByCategory = {};
    Map<String, num> incomeByMonth = {};
    Map<String, num> expenseByMonth = {};
    List<Map<String, dynamic>> recentTransactions = [];

    for (var doc in incomeSnap.docs) {
      final amt = num.tryParse(doc['amount'].toString()) ?? 0;
      totalIncome += amt;
      final month = _extractMonth(doc['date']);
      incomeByMonth[month] = (incomeByMonth[month] ?? 0) + amt;
      recentTransactions.add({
        'type': 'Income',
        'amount': amt,
        'date': doc['date'],
        'category': '',
        'name': '',
      });
    }
    for (var doc in expenseSnap.docs) {
      final amt = num.tryParse(doc['amount'].toString()) ?? 0;
      totalExpense += amt;
      final cat = doc['category'] ?? 'Other';
      expenseByCategory[cat] = (expenseByCategory[cat] ?? 0) + amt;
      final month = _extractMonth(doc['date']);
      expenseByMonth[month] = (expenseByMonth[month] ?? 0) + amt;
      recentTransactions.add({
        'type': 'Expense',
        'amount': amt,
        'date': doc['date'],
        'category': cat,
        'name': doc['name'] ?? '',
      });
    }
    recentTransactions.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'expenseByCategory': expenseByCategory,
      'incomeByMonth': incomeByMonth,
      'expenseByMonth': expenseByMonth,
      'recentTransactions': recentTransactions.take(5).toList(),
    };
  }

  String _extractMonth(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final parts = dateStr.split('-');
    if (parts.length < 2) return '';
    return '${parts[0]}-${parts[1]}'; // e.g., 2024-06
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report',
          style: GoogleFonts.poppins(
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color ?? Theme.of(context).colorScheme.onPrimary),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchReportData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          final totals = {
            'income': data['income'] ?? 0,
            'expense': data['expense'] ?? 0,
          };
          final expenseByCategory = data['expenseByCategory'] as Map<String, num>? ?? {};
          final incomeByMonth = data['incomeByMonth'] as Map<String, num>? ?? {};
          final expenseByMonth = data['expenseByMonth'] as Map<String, num>? ?? {};
          final recentTransactions = data['recentTransactions'] as List<Map<String, dynamic>>? ?? [];

          // Prepare months for table
          final months = {...incomeByMonth.keys, ...expenseByMonth.keys}.toList();
          months.sort();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
                          child: Column(
                            children: [
                              Text('Total Income', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              const SizedBox(height: 8),
                              Text('${totals['income']} FRW', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
                          child: Column(
                            children: [
                              Text('Total Expense', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              const SizedBox(height: 8),
                              Text('${totals['expense']} FRW', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (expenseByCategory.isNotEmpty) ...[
                  Text('Expenses by Category', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieSections(expenseByCategory),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                if (months.isNotEmpty) ...[
                  Text('Income & Expense by Month', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Table(
                    border: TableBorder.all(color: Theme.of(context).dividerColor),
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Month', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Income', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Expense', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...months.map((month) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(month, style: Theme.of(context).textTheme.bodyLarge),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${incomeByMonth[month] ?? 0} FRW', style: Theme.of(context).textTheme.bodyLarge),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${expenseByMonth[month] ?? 0} FRW', style: Theme.of(context).textTheme.bodyLarge),
                              ),
                            ],
                          ))
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
                if (_isPremium) ...[
                  Text('All Transactions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, category, or type',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 400,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchAllTransactions(),
                      builder: (context, txSnapshot) {
                        if (txSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (txSnapshot.hasError) {
                          return Center(child: Text('Error: ${txSnapshot.error}'));
                        }
                        final txs = txSnapshot.data ?? [];
                        final filteredTxs = _searchQuery.isEmpty
                            ? txs
                            : txs.where((tx) {
                                final name = (tx['name'] ?? '').toString().toLowerCase();
                                final category = (tx['category'] ?? '').toString().toLowerCase();
                                final type = (tx['type'] ?? '').toString().toLowerCase();
                                return name.contains(_searchQuery) ||
                                    category.contains(_searchQuery) ||
                                    type.contains(_searchQuery);
                              }).toList();
                        if (filteredTxs.isEmpty) {
                          return const Center(child: Text('No transactions found.'));
                        }
                        return ListView.builder(
                          itemCount: filteredTxs.length,
                          itemBuilder: (context, idx) {
                            final tx = filteredTxs[idx];
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  tx['type'] == 'Income' ? Icons.add_circle : Icons.remove_circle,
                                  color: tx['type'] == 'Income' ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                                ),
                                title: Text('${tx['type']}: ${tx['amount']} FRW', style: Theme.of(context).textTheme.bodyLarge),
                                subtitle: Text(
                                  'Date: ${tx['date']}'
                                  '${tx['category'] != '' ? '  Category: ${tx['category']}' : ''}'
                                  '${tx['name'] != '' ? '  Name: ${tx['name']}' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    icon: Icon(Icons.lock, color: Theme.of(context).colorScheme.error),
                    label: Text('Unlock All Transactions (Premium)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      widget.onRequirePremium?.call(1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please pay 100 FRW in Wallet to unlock premium features!'),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          },
          child: const Text('Back to Dashboard'),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, num> data) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.teal,
      Colors.amber,
      Colors.brown,
      Colors.pink,
    ];
    int i = 0;
    return data.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAllTransactions() async {
    final txSnap = await FirebaseFirestore.instance.collection('transactions').get();
    List<Map<String, dynamic>> txs = txSnap.docs.map((doc) => doc.data()).toList();
    txs.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return txs;
  }
} 