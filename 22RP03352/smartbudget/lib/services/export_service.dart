import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Export expenses to CSV format
  static Future<String> exportToCSV(int month, int year) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get expenses for the specified month
    final querySnapshot = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .orderBy('date', descending: true)
        .get();

    // Create CSV content
    final StringBuffer csv = StringBuffer();
    csv.writeln('Date,Category,Amount,Note');
    
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final category = data['category'] as String;
      final amount = data['amount'] as num;
      final note = data['note'] as String? ?? '';
      
      csv.writeln('${DateFormat('yyyy-MM-dd').format(date)},$category,$amount,"$note"');
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'expenses_${year}_${month.toString().padLeft(2, '0')}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv.toString());
    
    return file.path;
  }

  /// Export budget vs actual report to CSV
  static Future<String> exportBudgetReport(int month, int year) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get budgets
    final budgetSnapshot = await _firestore
        .collection('budgets')
        .doc(user.uid)
        .collection('user_budgets')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    // Get expenses
    final expenseSnapshot = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    // Create budget report
    final StringBuffer csv = StringBuffer();
    csv.writeln('Category,Budget,Actual,Remaining,Usage %');
    
    final Map<String, double> budgets = {};
    final Map<String, double> expenses = {};

    // Process budgets
    for (var doc in budgetSnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final amount = (data['amount'] as num).toDouble();
      budgets[category] = amount;
    }

    // Process expenses
    for (var doc in expenseSnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final amount = (data['amount'] as num).toDouble();
      expenses[category] = (expenses[category] ?? 0) + amount;
    }

    // Generate report rows
    for (var category in budgets.keys) {
      final budget = budgets[category] ?? 0;
      final actual = expenses[category] ?? 0;
      final remaining = budget - actual;
      final usage = budget > 0 ? (actual / budget * 100) : 0;
      
      csv.writeln('$category,$budget,$actual,$remaining,${usage.toStringAsFixed(1)}%');
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'budget_report_${year}_${month.toString().padLeft(2, '0')}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv.toString());
    
    return file.path;
  }

  /// Share file using device's share functionality
  static Future<void> shareFile(String filePath, String fileName) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(filePath)], text: 'BudgetWise Export: $fileName');
    } else {
      throw Exception('File not found: $filePath');
    }
  }

  /// Export monthly summary as text report
  static Future<String> exportMonthlySummary(int month, int year) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get data
    final budgetSnapshot = await _firestore
        .collection('budgets')
        .doc(user.uid)
        .collection('user_budgets')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    final expenseSnapshot = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    // Calculate totals
    double totalBudget = 0;
    double totalExpenses = 0;
    final Map<String, double> categoryBudgets = {};
    final Map<String, double> categoryExpenses = {};

    for (var doc in budgetSnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final amount = (data['amount'] as num).toDouble();
      categoryBudgets[category] = amount;
      totalBudget += amount;
    }

    for (var doc in expenseSnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final amount = (data['amount'] as num).toDouble();
      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
      totalExpenses += amount;
    }

    // Generate report
    final StringBuffer report = StringBuffer();
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
    
    report.writeln('BUDGETWISE MONTHLY REPORT');
    report.writeln('========================');
    report.writeln('Period: $monthName');
    report.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    report.writeln('');
    
    report.writeln('SUMMARY');
    report.writeln('-------');
    report.writeln('Total Budget: RWF ${totalBudget.toStringAsFixed(0)}');
    report.writeln('Total Spent: RWF ${totalExpenses.toStringAsFixed(0)}');
    report.writeln('Remaining: RWF ${(totalBudget - totalExpenses).toStringAsFixed(0)}');
    report.writeln('Usage: ${totalBudget > 0 ? ((totalExpenses / totalBudget) * 100).toStringAsFixed(1) : '0'}%');
    report.writeln('');
    
    report.writeln('DETAILED BREAKDOWN');
    report.writeln('------------------');
    for (var category in categoryBudgets.keys) {
      final budget = categoryBudgets[category] ?? 0;
      final actual = categoryExpenses[category] ?? 0;
      final remaining = budget - actual;
      final usage = budget > 0 ? (actual / budget * 100) : 0;
      
      report.writeln('$category:');
      report.writeln('  Budget: RWF ${budget.toStringAsFixed(0)}');
      report.writeln('  Spent: RWF ${actual.toStringAsFixed(0)}');
      report.writeln('  Remaining: RWF ${remaining.toStringAsFixed(0)}');
      report.writeln('  Usage: ${usage.toStringAsFixed(1)}%');
      report.writeln('');
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'monthly_summary_${year}_${month.toString().padLeft(2, '0')}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(report.toString());
    
    return file.path;
  }

  /// Get export options for the current month
  static List<Map<String, dynamic>> getExportOptions() {
    final now = DateTime.now();
    return [
      {
        'title': 'Export Expenses (CSV)',
        'description': 'Download all expenses for this month',
        'icon': '📊',
        'action': () => exportToCSV(now.month, now.year),
      },
      {
        'title': 'Export Budget Report (CSV)',
        'description': 'Budget vs actual spending comparison',
        'icon': '📈',
        'action': () => exportBudgetReport(now.month, now.year),
      },
      {
        'title': 'Export Monthly Summary (TXT)',
        'description': 'Detailed monthly financial report',
        'icon': '📋',
        'action': () => exportMonthlySummary(now.month, now.year),
      },
    ];
  }
} 