import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class EnhancedAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Data models for analytics
  static class CategoryData {
    final String category;
    final double amount;
    final double percentage;
    final int transactionCount;

    CategoryData({
      required this.category,
      required this.amount,
      required this.percentage,
      required this.transactionCount,
    });
  }

  static class MonthlyData {
    final String month;
    final double totalSpent;
    final double totalBudget;
    final double savings;

    MonthlyData({
      required this.month,
      required this.totalSpent,
      required this.totalBudget,
      required this.savings,
    });
  }

  static class SpendingInsight {
    final String title;
    final String description;
    final String type; // 'warning', 'positive', 'info'
    final double value;
    final String recommendation;

    SpendingInsight({
      required this.title,
      required this.description,
      required this.type,
      required this.value,
      required this.recommendation,
    });
  }

  // Get spending by category for pie chart
  static Future<List<CategoryData>> getCategorySpending({
    required int month,
    required int year,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCounts = {};
    double totalSpent = 0;

    for (var doc in querySnapshot.docs) {
      final category = doc['category'] as String;
      final amount = (doc['amount'] as num).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      totalSpent += amount;
    }

    return categoryTotals.entries.map((entry) {
      final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0;
      return CategoryData(
        category: entry.key,
        amount: entry.value,
        percentage: percentage,
        transactionCount: categoryCounts[entry.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  // Get monthly spending trends for line chart
  static Future<List<MonthlyData>> getMonthlyTrends({required int year}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final List<MonthlyData> monthlyData = [];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int month = 1; month <= 12; month++) {
      final expensesQuery = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      final budgetsQuery = await _firestore
          .collection('budgets')
          .doc(user.uid)
          .collection('user_budgets')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      double totalSpent = 0;
      double totalBudget = 0;

      for (var doc in expensesQuery.docs) {
        totalSpent += (doc['amount'] as num).toDouble();
      }

      for (var doc in budgetsQuery.docs) {
        totalBudget += (doc['amount'] as num).toDouble();
      }

      monthlyData.add(MonthlyData(
        month: months[month - 1],
        totalSpent: totalSpent,
        totalBudget: totalBudget,
        savings: totalBudget - totalSpent,
      ));
    }

    return monthlyData;
  }

  // Get daily spending for bar chart
  static Future<List<Map<String, dynamic>>> getDailySpending({
    required int month,
    required int year,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    final Map<int, double> dailyTotals = {};

    for (var doc in querySnapshot.docs) {
      final day = doc['day'] as int;
      final amount = (doc['amount'] as num).toDouble();
      dailyTotals[day] = (dailyTotals[day] ?? 0) + amount;
    }

    return dailyTotals.entries.map((entry) {
      return {
        'day': entry.key,
        'amount': entry.value,
        'date': DateTime(year, month, entry.key),
      };
    }).toList()
      ..sort((a, b) => a['day'].compareTo(b['day']));
  }

  // Generate spending insights
  static Future<List<SpendingInsight>> generateInsights({
    required int month,
    required int year,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final categoryData = await getCategorySpending(month: month, year: year);
    final monthlyTrends = await getMonthlyTrends(year: year);
    final dailySpending = await getDailySpending(month: month, year: year);

    final List<SpendingInsight> insights = [];

    // Top spending category insight
    if (categoryData.isNotEmpty) {
      final topCategory = categoryData.first;
      if (topCategory.percentage > 40) {
        insights.add(SpendingInsight(
          title: 'High Spending Alert',
          description: '${topCategory.category} accounts for ${topCategory.percentage.toStringAsFixed(1)}% of your spending',
          type: 'warning',
          value: topCategory.percentage,
          recommendation: 'Consider setting a budget limit for ${topCategory.category}',
        ));
      }
    }

    // Daily spending pattern insight
    if (dailySpending.isNotEmpty) {
      final maxDay = dailySpending.reduce((a, b) => a['amount'] > b['amount'] ? a : b);
      final avgAmount = dailySpending.map((d) => d['amount'] as double).reduce((a, b) => a + b) / dailySpending.length;
      
      if (maxDay['amount'] > avgAmount * 2) {
        insights.add(SpendingInsight(
          title: 'Unusual Spending Day',
          description: 'You spent ${NumberFormat.currency(symbol: 'RWF ').format(maxDay['amount'])} on day ${maxDay['day']}',
          type: 'info',
          value: maxDay['amount'],
          recommendation: 'Review what caused this spike in spending',
        ));
      }
    }

    // Monthly comparison insight
    if (monthlyTrends.length >= 2) {
      final currentMonth = monthlyTrends[month - 1];
      final previousMonth = monthlyTrends[month - 2];
      
      if (currentMonth.totalSpent > previousMonth.totalSpent * 1.2) {
        insights.add(SpendingInsight(
          title: 'Spending Increased',
          description: 'Your spending increased by ${((currentMonth.totalSpent / previousMonth.totalSpent - 1) * 100).toStringAsFixed(1)}% from last month',
          type: 'warning',
          value: currentMonth.totalSpent - previousMonth.totalSpent,
          recommendation: 'Review your spending habits and consider cutting back',
        ));
      } else if (currentMonth.totalSpent < previousMonth.totalSpent * 0.8) {
        insights.add(SpendingInsight(
          title: 'Great Job!',
          description: 'You reduced your spending by ${((1 - currentMonth.totalSpent / previousMonth.totalSpent) * 100).toStringAsFixed(1)}% from last month',
          type: 'positive',
          value: previousMonth.totalSpent - currentMonth.totalSpent,
          recommendation: 'Keep up the good work!',
        ));
      }
    }

    return insights;
  }

  // Export data to CSV
  static Future<String?> exportToCSV({
    required int month,
    required int year,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) return null;

      final querySnapshot = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      final StringBuffer csv = StringBuffer();
      csv.writeln('Date,Category,Amount,Note');

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final date = '${data['year']}-${data['month'].toString().padLeft(2, '0')}-${data['day'].toString().padLeft(2, '0')}';
        final category = data['category'] as String;
        final amount = data['amount'] as num;
        final note = data['note'] as String? ?? '';

        csv.writeln('$date,$category,$amount,"$note"');
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) return null;

      final fileName = 'budgetwise_export_${year}_${month.toString().padLeft(2, '0')}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv.toString());

      return file.path;
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  // Get budget vs actual comparison
  static Future<Map<String, dynamic>> getBudgetComparison({
    required int month,
    required int year,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final expensesQuery = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    final budgetsQuery = await _firestore
        .collection('budgets')
        .doc(user.uid)
        .collection('user_budgets')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    final Map<String, double> categorySpending = {};
    final Map<String, double> categoryBudgets = {};

    for (var doc in expensesQuery.docs) {
      final category = doc['category'] as String;
      final amount = (doc['amount'] as num).toDouble();
      categorySpending[category] = (categorySpending[category] ?? 0) + amount;
    }

    for (var doc in budgetsQuery.docs) {
      final category = doc['category'] as String;
      final amount = (doc['amount'] as num).toDouble();
      categoryBudgets[category] = amount;
    }

    return {
      'spending': categorySpending,
      'budgets': categoryBudgets,
    };
  }
} 