import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'premium_features_summary.dart';
import 'test_payment_screen.dart';

class AdvancedReportsScreen extends StatefulWidget {
  final void Function(int)? onRequirePremium;
  const AdvancedReportsScreen({super.key, this.onRequirePremium});

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'Last 3 Months', 'This Year'];
  bool _isPremium = false;
  final PremiumFeaturesManager _premiumManager = PremiumFeaturesManager();
  bool _advancedReportsUnlocked = false;
  bool _paywallDialogShown = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _checkAdvancedReportsUnlocked();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not authenticated'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final dateRange = _getDateRange();
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;

      print('Loading data for period: $_selectedPeriod');

      // Get income and expense data
      final incomeQuery = await FirebaseFirestore.instance
          .collection('income')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      final expenseQuery = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Process data
      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> categoryExpenses = {};
      Map<String, double> monthlyData = {};
      Map<String, int> transactionCounts = {'income': 0, 'expenses': 0};
      List<Map<String, dynamic>> recentTransactions = [];

      // Process income data
      for (var doc in incomeQuery.docs) {
        final amount = double.tryParse(doc.data()['amount']?.toString() ?? '0') ?? 0;
        totalIncome += amount;
        transactionCounts['income'] = (transactionCounts['income'] ?? 0) + 1;
        
        final date = doc.data()['date'] as Timestamp?;
        if (date != null) {
          final month = '${date.toDate().year}-${date.toDate().month.toString().padLeft(2, '0')}';
          monthlyData[month] = (monthlyData[month] ?? 0) + amount;
          
          recentTransactions.add({
            'type': 'income',
            'amount': amount,
            'category': doc.data()['category'] ?? 'Income',
            'date': date,
            'description': doc.data()['description'] ?? '',
          });
        }
      }

      // Process expense data
      for (var doc in expenseQuery.docs) {
        final amount = double.tryParse(doc.data()['amount']?.toString() ?? '0') ?? 0;
        totalExpense += amount;
        transactionCounts['expenses'] = (transactionCounts['expenses'] ?? 0) + 1;
        
        final category = doc.data()['category'] ?? 'Other';
        categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
        
        final date = doc.data()['date'] as Timestamp?;
        if (date != null) {
          final month = '${date.toDate().year}-${date.toDate().month.toString().padLeft(2, '0')}';
          monthlyData[month] = (monthlyData[month] ?? 0) - amount;
          
          recentTransactions.add({
            'type': 'expense',
            'amount': amount,
            'category': category,
            'date': date,
            'description': doc.data()['description'] ?? '',
          });
        }
      }

      // Sort recent transactions
      recentTransactions.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

      // Calculate metrics
      final netSavings = totalIncome - totalExpense;
      final savingsRate = totalIncome > 0 ? (netSavings / totalIncome * 100) : 0;
      final avgIncome = transactionCounts['income']! > 0 ? totalIncome / transactionCounts['income']! : 0;
      final avgExpense = transactionCounts['expenses']! > 0 ? totalExpense / transactionCounts['expenses']! : 0;

      setState(() {
        _reportData = {
          'totalIncome': totalIncome,
          'totalExpense': totalExpense,
          'netSavings': netSavings,
          'categoryExpenses': categoryExpenses,
          'monthlyData': monthlyData,
          'savingsRate': savingsRate,
          'transactionCounts': transactionCounts,
          'recentTransactions': recentTransactions.take(10).toList(),
          'avgIncome': avgIncome,
          'avgExpense': avgExpense,
          'period': _selectedPeriod,
        };
      });

      print('Report data loaded successfully');

    } catch (e) {
      print('Error loading report data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    DateTime safeMonthAdd(DateTime date, int months) {
      int year = date.year + ((date.month + months - 1) ~/ 12);
      int month = ((date.month + months - 1) % 12) + 1;
      return DateTime(year, month, 1);
    }
    switch (_selectedPeriod) {
      case 'This Week':
        final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
        return {
          'start': startOfWeek,
          'end': startOfWeek.add(const Duration(days: 6)),
        };
      case 'This Month':
        final start = DateTime(now.year, now.month, 1);
        final end = safeMonthAdd(start, 1).subtract(const Duration(days: 1));
        return {'start': start, 'end': end};
      case 'Last 3 Months':
        final start = safeMonthAdd(DateTime(now.year, now.month, 1), -2);
        final end = safeMonthAdd(DateTime(now.year, now.month, 1), 1).subtract(const Duration(days: 1));
        return {'start': start, 'end': end};
      case 'This Year':
        return {
          'start': DateTime(now.year, 1, 1),
          'end': DateTime(now.year, 12, 31),
        };
      default:
        final start = DateTime(now.year, now.month, 1);
        final end = safeMonthAdd(start, 1).subtract(const Duration(days: 1));
        return {'start': start, 'end': end};
    }
  }

  Future<void> _checkAdvancedReportsUnlocked() async {
    final unlocked = await _premiumManager.isFeatureUnlocked('advancedReports');
    setState(() {
      _advancedReportsUnlocked = unlocked;
    });
  }

  void _showPaywall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlock Advanced Reports'),
        content: Text('This is a premium feature. Please pay to unlock.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToPaymentScreen();
            },
            child: Text('Pay & Unlock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_advancedReportsUnlocked) {
      if (!_paywallDialogShown) {
        _paywallDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPaywall();
        });
      }
      return Scaffold(
        appBar: AppBar(title: Text('Advanced Reports')),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('This feature is locked. Please pay to unlock.'),
            ),
          ),
        ),
      );
    } else {
      _paywallDialogShown = false; // Reset for next time
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Advanced Reports',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Debug button for testing
          IconButton(
            icon: Icon(
              Icons.bug_report,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showDebugMenu(),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Period Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: InputDecoration(
                        labelText: 'Time Period',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: _periods.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPeriod = value!);
                        _loadReportData();
                      },
                    ),
                  ),

                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Income',
                            '${_reportData['totalIncome']?.toStringAsFixed(0) ?? '0'} FRW',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Expenses',
                            '${_reportData['totalExpense']?.toStringAsFixed(0) ?? '0'} FRW',
                            Icons.trending_down,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Net Savings',
                            '${_reportData['netSavings']?.toStringAsFixed(0) ?? '0'} FRW',
                            Icons.savings,
                            (_reportData['netSavings'] ?? 0) >= 0 ? Colors.blue : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Savings Rate',
                            '${_reportData['savingsRate']?.toStringAsFixed(1) ?? '0'}%',
                            Icons.percent,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Additional metrics
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Avg Income',
                            '${_reportData['avgIncome']?.toStringAsFixed(0) ?? '0'} FRW',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Avg Expense',
                            '${_reportData['avgExpense']?.toStringAsFixed(0) ?? '0'} FRW',
                            Icons.trending_down,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Transaction counts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Income Count',
                            '${_reportData['transactionCounts']?['income'] ?? 0}',
                            Icons.add_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Expense Count',
                            '${_reportData['transactionCounts']?['expenses'] ?? 0}',
                            Icons.remove_circle,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Spending by Category Chart
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending by Category',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieChartSections(),
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryLegend(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Monthly Trend Chart
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Cash Flow',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(show: false),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _buildLineChartSpots(),
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Transactions
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentTransactionsList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Insights
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Spending Insights',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._buildAIInsights(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  if (!_advancedReportsUnlocked) ...[
                    // Premium Unlock Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade50,
                            Colors.purple.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 48,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unlock Advanced Reports',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get access to detailed analytics, AI insights, and advanced charts',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Payment Options
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.payment, color: Colors.white),
                                  label: Text('Pay 100 FRW', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _navigateToPaymentScreen(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: Icon(Icons.bug_report, color: Colors.blue.shade600),
                                  label: Text('Test Unlock', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue.shade600,
                                    side: BorderSide(color: Colors.blue.shade600),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _showDebugMenu(),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Quick Test Buttons
                          Text(
                            'Quick Test Options:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildQuickTestButton('Free Test', Colors.green, () async {
                                try {
                                  await _premiumManager.grantPremiumAccess('test_payment', 'free_test_${DateTime.now().millisecondsSinceEpoch}');
                                  await _checkAdvancedReportsUnlocked();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Advanced Reports unlocked for testing! 🎉'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  setState(() {});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }),
                              _buildQuickTestButton('Debug Unlock', Colors.purple, () => _unlockAdvancedReports()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final categoryExpenses = _reportData['categoryExpenses'] as Map<String, double>? ?? {};
    final total = categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);
    
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No Data',
          color: Colors.grey,
          radius: 60,
        ),
      ];
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    int colorIndex = 0;
    return categoryExpenses.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[colorIndex % colors.length],
        radius: 60,
        titleStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryLegend() {
    final categoryExpenses = _reportData['categoryExpenses'] as Map<String, double>? ?? {};
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categoryExpenses.entries.map((entry) {
        final index = categoryExpenses.keys.toList().indexOf(entry.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              entry.key,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<FlSpot> _buildLineChartSpots() {
    final monthlyData = _reportData['monthlyData'] as Map<String, double>? ?? {};
    if (monthlyData.isEmpty) {
      return [FlSpot(0, 0)];
    }
    final sortedMonths = monthlyData.keys.toList()..sort();
    
    return sortedMonths.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), monthlyData[entry.value] ?? 0);
    }).toList();
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTopCategory() {
    final categoryExpenses = _reportData['categoryExpenses'] as Map<String, double>? ?? {};
    if (categoryExpenses.isEmpty) return 'No categories';
    
    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories.first.key;
  }

  Widget _buildRecentTransactionsList() {
    final recentTransactions = _reportData['recentTransactions'] as List<Map<String, dynamic>>? ?? [];
    
    if (recentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No recent transactions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      );
    }

    return Column(
      children: recentTransactions.map((transaction) {
        final isIncome = transaction['type'] == 'income';
        final amount = transaction['amount'] as double;
        final category = transaction['category'] as String;
        final date = transaction['date'] as Timestamp;
        final description = transaction['description'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isIncome ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isIncome ? Icons.add_circle : Icons.remove_circle,
                color: isIncome ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    Text(
                      '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${amount.toStringAsFixed(0)} FRW',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildAIInsights() {
    final insights = <Widget>[];
    final savingsRate = _reportData['savingsRate'] as double? ?? 0;
    final totalExpense = _reportData['totalExpense'] as double? ?? 0;
    final topCategory = _getTopCategory();

    // Savings rate insight
    if (savingsRate > 20) {
      insights.add(_buildInsightCard(
        'Excellent Savings Rate! 🎉',
        'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income.',
        Icons.thumb_up,
        Colors.green,
      ));
    } else if (savingsRate > 10) {
      insights.add(_buildInsightCard(
        'Good Savings Rate 👍',
        'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income.',
        Icons.trending_up,
        Colors.blue,
      ));
    } else if (savingsRate > 0) {
      insights.add(_buildInsightCard(
        'Room for Improvement 📈',
        'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income.',
        Icons.lightbulb,
        Colors.orange,
      ));
    } else {
      insights.add(_buildInsightCard(
        'Spending More Than Income ⚠️',
        'Consider reducing expenses or increasing income.',
        Icons.warning,
        Colors.red,
      ));
    }

    // Top category insight
    if (topCategory != 'No categories' && totalExpense > 0) {
      final categoryExpenses = _reportData['categoryExpenses'] as Map<String, double>? ?? {};
      final topCategoryAmount = categoryExpenses[topCategory] ?? 0;
      final topCategoryPercentage = (topCategoryAmount / totalExpense * 100);
      
      if (topCategoryPercentage > 50) {
        insights.add(_buildInsightCard(
          'High Concentration in $topCategory',
          '${topCategoryPercentage.toStringAsFixed(1)}% of your expenses.',
          Icons.warning,
          Colors.orange,
        ));
      } else {
        insights.add(_buildInsightCard(
          'Well-Diversified Spending',
          'Good spending distribution across categories.',
          Icons.check_circle,
          Colors.green,
        ));
      }
    }

    // Add spacing
    for (int i = 0; i < insights.length - 1; i++) {
      insights.insert(i * 2 + 1, const SizedBox(height: 12));
    }

    return insights;
  }

  void _showDebugMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Tools', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('Show Debug Info'),
              subtitle: Text('Display current report data'),
              onTap: () {
                Navigator.of(context).pop();
                _showDebugInfo();
              },
            ),
            ListTile(
              leading: Icon(Icons.data_usage, color: Colors.green),
              title: Text('Create Test Data'),
              subtitle: Text('Add sample income/expense data'),
              onTap: () {
                Navigator.of(context).pop();
                _createTestData();
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: Colors.orange),
              title: Text('Force Refresh'),
              subtitle: Text('Reload data from Firestore'),
              onTap: () {
                Navigator.of(context).pop();
                _loadReportData();
              },
            ),
            ListTile(
              leading: Icon(Icons.lock_open, color: Colors.purple),
              title: Text('Unlock Advanced Reports'),
              subtitle: Text('Unlock premium feature for testing'),
              onTap: () {
                Navigator.of(context).pop();
                _unlockAdvancedReports();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Information', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Period: ${_reportData['period'] ?? 'N/A'}'),
            Text('Premium Unlocked: $_advancedReportsUnlocked'),
            const SizedBox(height: 16),
            Text('Income: ${_reportData['totalIncome']?.toStringAsFixed(0) ?? '0'} FRW'),
            Text('Expenses: ${_reportData['totalExpense']?.toStringAsFixed(0) ?? '0'} FRW'),
            Text('Savings: ${_reportData['netSavings']?.toStringAsFixed(0) ?? '0'} FRW'),
            Text('Rate: ${_reportData['savingsRate']?.toStringAsFixed(1) ?? '0'}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      // Create test income data
      for (int i = 0; i < 5; i++) {
        final incomeRef = FirebaseFirestore.instance.collection('income').doc();
        batch.set(incomeRef, {
          'userId': user.uid,
          'amount': (50000 + (i * 10000)).toString(),
          'category': 'Salary',
          'description': 'Test income ${i + 1}',
          'date': Timestamp.fromDate(now.subtract(Duration(days: i * 7))),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Create test expense data
      final categories = ['Food', 'Transport', 'Entertainment', 'Utilities', 'Shopping'];
      for (int i = 0; i < 10; i++) {
        final expenseRef = FirebaseFirestore.instance.collection('expenses').doc();
        batch.set(expenseRef, {
          'userId': user.uid,
          'amount': (5000 + (i * 2000)).toString(),
          'category': categories[i % categories.length],
          'description': 'Test expense ${i + 1}',
          'date': Timestamp.fromDate(now.subtract(Duration(days: i * 3))),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await _loadReportData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test data created successfully!')),
      );
    } catch (e) {
      print('Error creating test data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating test data: $e')),
      );
    }
  }

  Future<void> _unlockAdvancedReports() async {
    try {
      await _premiumManager.unlockFeature('advancedReports');
      await _checkAdvancedReportsUnlocked();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Advanced Reports unlocked successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload the screen to show the unlocked content
      setState(() {});
      
    } catch (e) {
      print('Error unlocking Advanced Reports: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unlocking Advanced Reports: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPaymentScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TestPaymentScreen(),
      ),
    );
    // After returning from payment, re-check unlock status
    await _checkAdvancedReportsUnlocked();
    setState(() {});
  }

  Widget _buildQuickTestButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
} 