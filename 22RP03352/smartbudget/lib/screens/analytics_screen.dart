import 'package:flutter/material.dart';
import 'premium_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../main.dart'; // For selectedMonthYear

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final selected = selectedMonthYear.value;
    final selectedMonth = selected.month;
    final selectedYear = selected.year;

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
          appBar: AppBar(title: Text('Analytics & Reports')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Spending by Category (${selectedMonth}/${selectedYear})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('expenses')
                        .doc(user!.uid)
                        .collection('user_expenses')
                        .where('month', isEqualTo: selectedMonth)
                        .where('year', isEqualTo: selectedYear)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(child: Text('No expenses found for this month.'));
                      }
                      // Aggregate by category
                      final Map<String, double> categoryTotals = {};
                      double totalSpent = 0;
                      for (var doc in docs) {
                        final category = doc['category'] as String;
                        final amount = (doc['amount'] as num).toDouble();
                        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
                        totalSpent += amount;
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
                                  return PieChartSectionData(
                                    color: color,
                                    value: entry.value,
                                    title: entry.key,
                                    radius: 60,
                                    titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 30,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Total Spent: RWF ${totalSpent.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Export to CSV coming soon!')),
                              );
                            },
                            icon: Icon(Icons.download),
                            label: Text('Export CSV'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 