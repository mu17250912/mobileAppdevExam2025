import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({Key? key}) : super(key: key);

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  String category = 'Food';
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  Future<void> _saveExpense() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final amount = double.tryParse(amountController.text) ?? 0.0;
    final note = noteController.text;

    // 1. Save expense to Firestore
    await FirebaseFirestore.instance.collection('expenses').add({
      'userId': user.uid,
      'category': category,
      'amount': amount,
      'note': note,
      'date': DateTime.now(),
    });

    // 2. Fetch budget for this category
    final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(user.uid).get();
    final categoryBudget = (budgetDoc.data()?[category] ?? 0).toDouble();

    // 3. Calculate total spent for this category
    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .where('category', isEqualTo: category)
        .get();

    double totalSpent = 0;
    for (var doc in expensesSnapshot.docs) {
      totalSpent += (doc.data()['amount'] ?? 0).toDouble();
    }

    // 4. Calculate percent used
    double percentUsed = (categoryBudget == 0) ? 0 : (totalSpent / categoryBudget) * 100;

    // 5. Show notification
    if (percentUsed >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔴 Your $category budget is finished!')),
      );
    } else if (percentUsed >= 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🟠 Warning: You've used 90% of your $category budget!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: category,
              items: ['Food', 'Transport', 'Airtime', 'Rent', 'Shopping']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => category = val!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (RWF)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _saveExpense();
                // Fetch budget and total spent again for dialog
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(user.uid).get();
                  final categoryBudget = (budgetDoc.data()?[category] ?? 0).toDouble();
                  final expensesSnapshot = await FirebaseFirestore.instance
                      .collection('expenses')
                      .where('userId', isEqualTo: user.uid)
                      .where('category', isEqualTo: category)
                      .get();
                  double totalSpent = 0;
                  for (var doc in expensesSnapshot.docs) {
                    totalSpent += (doc.data()['amount'] ?? 0).toDouble();
                  }
                  double remaining = categoryBudget - totalSpent;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Budget Summary for $category'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Budget: RWF ${categoryBudget.toStringAsFixed(2)}'),
                          Text('Total Spent: RWF ${totalSpent.toStringAsFixed(2)}'),
                          Text('Remaining: RWF ${remaining.toStringAsFixed(2)}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Pay'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // TODO: Navigate to View History page
              },
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
} 