import 'package:flutter/material.dart';
import 'premium_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../main.dart'; // For selectedMonthYear
import '../services/analytics_service.dart';
import '../services/export_service.dart'; // Import export service

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedMonth = selectedMonthYear.value.month;
    _selectedYear = selectedMonthYear.value.year;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Text('📊', style: TextStyle(fontSize: 24)),
              title: Text('Export Expenses (CSV)'),
              subtitle: Text('Download all expenses for this month'),
              onTap: () async {
                Navigator.of(context).pop();
                await _exportData('expenses');
              },
            ),
            ListTile(
              leading: Text('📈', style: TextStyle(fontSize: 24)),
              title: Text('Export Budget Report (CSV)'),
              subtitle: Text('Budget vs actual spending comparison'),
              onTap: () async {
                Navigator.of(context).pop();
                await _exportData('budget');
              },
            ),
            ListTile(
              leading: Text('📋', style: TextStyle(fontSize: 24)),
              title: Text('Export Monthly Summary (TXT)'),
              subtitle: Text('Detailed monthly financial report'),
              onTap: () async {
                Navigator.of(context).pop();
                await _exportData('summary');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String type) async {
    try {
      setState(() {
        // Show loading indicator
      });

      String filePath;
      String fileName;

      switch (type) {
        case 'expenses':
          filePath = await ExportService.exportToCSV(_selectedMonth, _selectedYear);
          fileName = 'expenses_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.csv';
          break;
        case 'budget':
          filePath = await ExportService.exportBudgetReport(_selectedMonth, _selectedYear);
          fileName = 'budget_report_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.csv';
          break;
        case 'summary':
          filePath = await ExportService.exportMonthlySummary(_selectedMonth, _selectedYear);
          fileName = 'monthly_summary_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.txt';
          break;
        default:
          throw Exception('Unknown export type');
      }

      await ExportService.shareFile(filePath, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export completed! File shared.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<bool>(
      future: PremiumService.isPremium(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Analytics & Reports')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: Text('Analytics & Reports')),
            body: Center(child: Text('Upgrade to Premium to access advanced analytics!')),
          );
        }
        // Premium content
        return Scaffold(
          appBar: AppBar(
            title: Text('Analytics & Reports'),
            actions: [
              IconButton(
                icon: Icon(Icons.download),
                onPressed: _showExportOptions,
                tooltip: 'Export Data',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Categories'),
                Tab(text: 'Trends'),
                Tab(text: 'Budget vs Actual'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryChart(),
              _buildTrendsChart(),
              _buildBudgetVsActualChart(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Spending by Category (${_selectedMonth}/${_selectedYear})',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: AnalyticsService.getSpendingByCategory(_selectedMonth, _selectedYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final categoryTotals = snapshot.data ?? {};
                if (categoryTotals.isEmpty) {
                  return Center(child: Text('No expenses found for this month.'));
                }

                final colors = [
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                  Colors.purple,
                  Colors.red,
                  Colors.teal,
                  Colors.brown,
                  Colors.pink,
                  Colors.indigo,
                  Colors.cyan,
                ];

                final totalSpent = categoryTotals.values.fold<double>(0, (sum, amount) => sum + amount);
                int colorIdx = 0;

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: categoryTotals.entries.map((entry) {
                            final color = colors[colorIdx % colors.length];
                            colorIdx++;
                            final percentage = totalSpent > 0 ? (entry.value / totalSpent * 100) : 0;
                            return PieChartSectionData(
                              color: color,
                              value: entry.value,
                              title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Total Spent: RWF ${totalSpent.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: categoryTotals.length,
                        itemBuilder: (context, index) {
                          final entry = categoryTotals.entries.elementAt(index);
                          final color = colors[index % colors.length];
                          final percentage = totalSpent > 0 ? (entry.value / totalSpent * 100) : 0;
                          return ListTile(
                            leading: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(entry.key),
                            trailing: Text(
                              'RWF ${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Monthly Spending Trends (Last 6 Months)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: AnalyticsService.getMonthlyTrends(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final trends = snapshot.data ?? [];
                if (trends.isEmpty) {
                  return Center(child: Text('No spending data available.'));
                }

                final maxAmount = trends.fold<double>(0, (max, trend) => 
                  trend['amount'] > max ? trend['amount'] : max);

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxAmount * 1.2,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < trends.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        trends[value.toInt()]['month'],
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    'RWF ${value.toInt()}',
                                    style: TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: trends.asMap().entries.map((entry) {
                            final index = entry.key;
                            final trend = entry.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: trend['amount'],
                                  color: Colors.green,
                                  width: 20,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: trends.length,
                        itemBuilder: (context, index) {
                          final trend = trends[index];
                          return ListTile(
                            leading: Icon(Icons.trending_up, color: Colors.green),
                            title: Text(trend['month']),
                            trailing: Text(
                              'RWF ${trend['amount'].toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetVsActualChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Budget vs Actual Spending (${_selectedMonth}/${_selectedYear})',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: AnalyticsService.getBudgetVsActual(_selectedMonth, _selectedYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data ?? {};
                if (data.isEmpty) {
                  return Center(child: Text('No budget data available for this month.'));
                }

                final budget = data['budget'] ?? 0.0;
                final actual = data['actual'] ?? 0.0;
                final remaining = data['remaining'] ?? 0.0;
                final percentage = data['percentage'] ?? 0.0;
                final maxValue = [budget, actual].reduce((a, b) => a > b ? a : b);

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxValue * 1.2,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return Text('Budget');
                                  if (value == 1) return Text('Actual');
                                  return Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    'RWF ${value.toInt()}',
                                    style: TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: budget,
                                  color: Colors.blue,
                                  width: 30,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: actual,
                                  color: actual > budget ? Colors.red : Colors.green,
                                  width: 30,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Budget:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('RWF ${budget.toStringAsFixed(0)}', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Actual:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('RWF ${actual.toStringAsFixed(0)}', 
                                  style: TextStyle(color: actual > budget ? Colors.red : Colors.green)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Remaining:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('RWF ${remaining.toStringAsFixed(0)}', 
                                  style: TextStyle(color: remaining >= 0 ? Colors.green : Colors.red)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('${percentage.toStringAsFixed(1)}%', 
                                  style: TextStyle(color: percentage > 100 ? Colors.red : Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 