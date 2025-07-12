import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnhancedAnalyticsService {
  static final EnhancedAnalyticsService _instance = EnhancedAnalyticsService._internal();
  factory EnhancedAnalyticsService() => _instance;
  EnhancedAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get comprehensive analytics data
  Future<Map<String, dynamic>> getComprehensiveAnalytics(String period) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final now = DateTime.now();
      int month = now.month;
      int year = now.year;
      if (period == 'year') {
        // For year, fetch all months in the year
        month = 0;
      }
      // Fetch budgets
      final budgetsQuery = await _firestore
          .collection('budgets')
          .doc(user.uid)
          .collection('user_budgets')
          .where('year', isEqualTo: year)
          .get();
      double totalBudget = 0.0;
      for (var doc in budgetsQuery.docs) {
        if (month == 0 || doc['month'] == month) {
          totalBudget += (doc['amount'] as num).toDouble();
        }
      }
      // Fetch expenses
      final expensesQuery = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .where('year', isEqualTo: year)
          .get();
      List<Map<String, dynamic>> expenses = [];
      for (var doc in expensesQuery.docs) {
        if (month == 0 || doc['month'] == month) {
          expenses.add(doc.data());
        }
      }
      final totalSpent = expenses.fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0.0));
      final savings = totalBudget - totalSpent;
      final avgDaily = expenses.isNotEmpty ? totalSpent / 30 : 0.0;
      // Generate insights
      final insights = _generateInsights(expenses, totalSpent, totalBudget);
      // Trend data and other analytics can be added as needed
      return {
        'totalSpent': totalSpent,
        'budget': totalBudget,
        'savings': savings,
        'avgDailySpending': avgDaily,
        'insights': insights,
      };
    } catch (e) {
      throw Exception('Failed to get comprehensive analytics: $e');
    }
  }

  // Get expense history
  Future<List<Map<String, dynamic>>> getExpenseHistory(String period) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final now = DateTime.now();
      int month = now.month;
      int year = now.year;
      if (period == 'year') {
        month = 0;
      }
      final expensesQuery = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .where('year', isEqualTo: year)
          .get();
      List<Map<String, dynamic>> expenses = [];
      for (var doc in expensesQuery.docs) {
        if (month == 0 || doc['month'] == month) {
          expenses.add(doc.data());
        }
      }
      expenses.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
      return expenses;
    } catch (e) {
      throw Exception('Failed to get expense history: $e');
    }
  }

  // Get category spending
  Future<Map<String, double>> getCategorySpending(String period) async {
    try {
      final expenses = await getExpenseHistory(period);
      final categorySpending = <String, double>{};
      for (final expense in expenses) {
        final category = expense['category'] ?? 'Other';
        final amount = expense['amount'] ?? 0.0;
        categorySpending[category] = (categorySpending[category] ?? 0.0) + amount;
      }
      return categorySpending;
    } catch (e) {
      throw Exception('Failed to get category spending: $e');
    }
  }

  // Get budget insights
  Future<List<Map<String, dynamic>>> getBudgetInsights(String period) async {
    try {
      final analytics = await getComprehensiveAnalytics(period);
      final totalSpent = analytics['totalSpent'] ?? 0.0;
      final budget = analytics['budget'] ?? 0.0;
      final insights = <Map<String, dynamic>>[];
      if (budget > 0) {
        final percentage = (totalSpent / budget) * 100;
        if (percentage > 90) {
          insights.add({
            'type': 'warning',
            'title': 'Budget Alert',
            'message': 'You\'ve used ${percentage.toStringAsFixed(1)}% of your budget',
            'icon': 'warning',
          });
        } else if (percentage < 50) {
          insights.add({
            'type': 'positive',
            'title': 'Great Progress',
            'message': 'You\'re only using ${percentage.toStringAsFixed(1)}% of your budget',
            'icon': 'check_circle',
          });
        }
      }
      return insights;
    } catch (e) {
      throw Exception('Failed to get budget insights: $e');
    }
  }

  // New: Get analytics for a specific month and year
  Future<Map<String, dynamic>> getComprehensiveAnalyticsForMonthYear(int month, int year) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      // Fetch budgets
      final budgetsQuery = await _firestore
          .collection('budgets')
          .doc(user.uid)
          .collection('user_budgets')
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();
      double totalBudget = 0.0;
      for (var doc in budgetsQuery.docs) {
        totalBudget += (doc['amount'] as num).toDouble();
      }
      // Fetch expenses
      final expensesQuery = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();
      List<Map<String, dynamic>> expenses = [];
      for (var doc in expensesQuery.docs) {
        expenses.add(doc.data());
      }
      final totalSpent = expenses.fold<double>(0, (sum, e) => sum + (e['amount'] ?? 0.0));
      final savings = totalBudget - totalSpent;
      final avgDaily = expenses.isNotEmpty ? totalSpent / 30 : 0.0;
      final insights = _generateInsights(expenses, totalSpent, totalBudget);
      return {
        'totalSpent': totalSpent,
        'budget': totalBudget,
        'savings': savings,
        'avgDailySpending': avgDaily,
        'insights': insights,
      };
    } catch (e) {
      throw Exception('Failed to get analytics for month/year: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getExpenseHistoryForMonthYear(int month, int year) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final expensesQuery = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();
      List<Map<String, dynamic>> expenses = [];
      for (var doc in expensesQuery.docs) {
        expenses.add(doc.data());
      }
      expenses.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
      return expenses;
    } catch (e) {
      throw Exception('Failed to get expense history for month/year: $e');
    }
  }

  Future<Map<String, double>> getCategorySpendingForMonthYear(int month, int year) async {
    try {
      final expenses = await getExpenseHistoryForMonthYear(month, year);
      final categorySpending = <String, double>{};
      for (final expense in expenses) {
        final category = expense['category'] ?? 'Other';
        final amount = expense['amount'] ?? 0.0;
        categorySpending[category] = (categorySpending[category] ?? 0.0) + amount;
      }
      return categorySpending;
    } catch (e) {
      throw Exception('Failed to get category spending for month/year: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBudgetInsightsForMonthYear(int month, int year) async {
    try {
      final analytics = await getComprehensiveAnalyticsForMonthYear(month, year);
      final totalSpent = analytics['totalSpent'] ?? 0.0;
      final budget = analytics['budget'] ?? 0.0;
      final insights = <Map<String, dynamic>>[];
      if (budget > 0) {
        final percentage = (totalSpent / budget) * 100;
        if (percentage > 90) {
          insights.add({
            'type': 'warning',
            'title': 'Budget Alert',
            'message': 'You\'ve used ${percentage.toStringAsFixed(1)}% of your budget',
            'icon': 'warning',
          });
        } else if (percentage < 50) {
          insights.add({
            'type': 'positive',
            'title': 'Great Progress',
            'message': 'You\'re only using ${percentage.toStringAsFixed(1)}% of your budget',
            'icon': 'check_circle',
          });
        }
      }
      return insights;
    } catch (e) {
      throw Exception('Failed to get budget insights for month/year: $e');
    }
  }

  // Generate insights based on spending patterns
  List<String> _generateInsights(List<Map<String, dynamic>> expenses, double totalSpent, double budget) {
    final insights = <String>[];
    if (expenses.isEmpty) {
      insights.add('No expenses recorded yet. Start tracking to get insights!');
      return insights;
    }
    // Most expensive category
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      final category = expense['category'] ?? 'Other';
      final amount = expense['amount'] ?? 0.0;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }
    if (categoryTotals.isNotEmpty) {
      final maxCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('${maxCategory.key} is your highest spending category at RWF ${maxCategory.value.toStringAsFixed(0)}');
    }
    // Budget utilization
    if (budget > 0) {
      final percentage = (totalSpent / budget) * 100;
      if (percentage > 100) {
        insights.add('You\'ve exceeded your budget by ${(percentage - 100).toStringAsFixed(1)}%');
      } else if (percentage > 80) {
        insights.add('You\'ve used ${percentage.toStringAsFixed(1)}% of your budget');
      } else {
        insights.add('You\'re on track with ${percentage.toStringAsFixed(1)}% of budget used');
      }
    }
    // Spending frequency
    final avgAmount = totalSpent / expenses.length;
    insights.add('Average expense amount: RWF ${avgAmount.toStringAsFixed(0)}');
    return insights;
  }
} 