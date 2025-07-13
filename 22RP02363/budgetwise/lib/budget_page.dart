import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({Key? key}) : super(key: key);

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final foodController = TextEditingController();
  final transportController = TextEditingController();
  final airtimeController = TextEditingController();
  final rentController = TextEditingController();
  String selectedWeek = 'Week 1';
  final List<String> weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
  String budgetMode = 'Weekly';
  final List<String> budgetModes = ['Weekly', 'Monthly'];
  String selectedCategory = 'Food';
  String? selectedFoodType;
  final foodTypes = ['Rice', 'Beans', 'Meat', 'Vegetables', 'Other'];
  final itemNameController = TextEditingController();
  final amountController = TextEditingController();

  Future<void> _saveBudget() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final amount = double.tryParse(amountController.text) ?? 0.0;
      final now = DateTime.now();
      if (budgetMode == 'Weekly') {
        await FirebaseFirestore.instance.collection('budgets').doc(user.uid).set({
          selectedWeek: {
            selectedCategory: amount,
            '${selectedCategory}_budgetSetAt': now,
          }
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Budget saved for $selectedWeek!')),
        );
      } else {
        await FirebaseFirestore.instance.collection('budgets').doc(user.uid).set({
          selectedCategory: amount,
          '${selectedCategory}_budgetSetAt': now,
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monthly budget saved!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _viewBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('budgets').doc(user.uid).get();
    final data = doc.data();
    if (budgetMode == 'Weekly') {
      final weekData = data?[selectedWeek];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Your Planned Budget for $selectedWeek'),
          content: weekData == null
              ? const Text('No budget found for this week.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Food: RWF ${weekData['Food'] ?? 0}'),
                    Text('Transport: RWF ${weekData['Transport'] ?? 0}'),
                    Text('Airtime: RWF ${weekData['Airtime'] ?? 0}'),
                    Text('Beverages: RWF ${weekData['Beverages'] ?? 0}'),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your Planned Monthly Budget'),
          content: data == null
              ? const Text('No monthly budget found.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Food: RWF ${data['Food'] ?? 0}'),
                    Text('Transport: RWF ${data['Transport'] ?? 0}'),
                    Text('Airtime: RWF ${data['Airtime'] ?? 0}'),
                    Text('Beverages: RWF ${data['Beverages'] ?? 0}'),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Budget'),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.green[700], size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'Budget Setup',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1.2),
                    DropdownButtonFormField<String>(
                      value: budgetMode,
                      items: budgetModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => budgetMode = val!),
                      decoration: const InputDecoration(labelText: 'Budget Mode', prefixIcon: Icon(Icons.calendar_view_month)),
                    ),
                    if (budgetMode == 'Weekly') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedWeek,
                        items: weeks.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: (val) => setState(() => selectedWeek = val!),
                        decoration: const InputDecoration(labelText: 'Select Week', prefixIcon: Icon(Icons.view_week)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: ['Food', 'Transport', 'Airtime', 'Beverages']
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCategory = val!;
                          selectedFoodType = null;
                          itemNameController.clear();
                        });
                      },
                      decoration: InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: 'Amount (RWF)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveBudget,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Budget'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _viewBudget,
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Budget'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label (RWF)',
        prefixIcon: Icon(icon, color: Colors.green[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
    );
  }
} 