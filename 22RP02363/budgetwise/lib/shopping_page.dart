import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notifications_service.dart';
import 'notifications_page.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_page.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({Key? key}) : super(key: key);

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  String category = 'Food';
  final itemController = TextEditingController();
  final amountController = TextEditingController();
  String? selectedFoodType;
  final foodTypes = ['Rice', 'Beans', 'Meat', 'Vegetables', 'Other'];
  bool isLoading = false;
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        notificationCount = snapshot.docs.length;
      });
    });
  }

  Future<void> _addShoppingItem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String item = '';
    if (category == 'Food') {
      if (selectedFoodType == null) {
        item = '';
      } else if (selectedFoodType == 'Other') {
        item = itemController.text.trim();
      } else {
        item = selectedFoodType!;
      }
    } else {
      item = itemController.text.trim();
    }
    final amount = double.tryParse(amountController.text) ?? 0.0;
    if (item.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid item and amount.')),
      );
      return;
    }
    final budget = await _getCategoryBudget();
    if (budget == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Budget Set'),
          content: Text('You have no budget set for $category. Please set a budget before making a payment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    await FirebaseFirestore.instance.collection('expenses').add({
      'userId': user.uid,
      'category': category,
      'amount': amount,
      'note': item,
      'date': DateTime.now(),
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCategory', category);
    final spent = await _getTotalCategorySpent();
    final remaining = budget - spent;
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': user.uid,
      'title': 'Shopping Summary',
      'body': 'You spent RWF ${amount.toStringAsFixed(2)} on ${item.isNotEmpty ? item : category}. Remaining: RWF ${remaining.toStringAsFixed(2)}',
      'date': DateTime.now(),
    });
    itemController.clear();
    amountController.clear();
    if (mounted) setState(() => isLoading = false);
    // Show dialog with spent and remaining
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You spent RWF ${amount.toStringAsFixed(2)} on $item.'),
            const SizedBox(height: 8),
            Text('Remaining for $category: RWF ${remaining.toStringAsFixed(2)}'),
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
    // Optionally, you can trigger a dashboard update if needed
  }

  Future<double> _getCategoryBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;
    final doc = await FirebaseFirestore.instance.collection('budgets').doc(user.uid).get();
    return (doc.data()?[category] ?? 0).toDouble();
  }

  Future<double> _getTotalCategorySpent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;
    final snapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .where('category', isEqualTo: category)
        .get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final docData = doc.data() as Map<String, dynamic>;
      final amount = docData['amount'];
      if (amount is int) {
        total += amount.toDouble();
      } else if (amount is double) {
        total += amount;
      } else if (amount is String) {
        total += double.tryParse(amount) ?? 0.0;
      } else {
        total += 0.0;
      }
    }
    return total;
  }

  Stream<QuerySnapshot> _shoppingHistoryStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                items: ['Food', 'Transport', 'Airtime', 'Beverages']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) async {
                  setState(() {
                    category = val!;
                    selectedFoodType = null;
                    itemController.clear();
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('selectedCategory', category);
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 20),
              if (category == 'Food') ...[
                DropdownButtonFormField<String>(
                  value: selectedFoodType,
                  items: foodTypes
                      .map((food) => DropdownMenuItem(value: food, child: Text(food)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedFoodType = val),
                  decoration: const InputDecoration(labelText: 'Type of Food'),
                ),
                if (selectedFoodType == 'Other')
                  TextField(
                    controller: itemController,
                    decoration: const InputDecoration(labelText: 'Specify Food Item'),
                  ),
              ] else if (category == 'Transport') ...[
                TextField(
                  controller: itemController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ] else if (category == 'Airtime') ...[
                TextField(
                  controller: itemController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
              ] else if (category == 'Beverages') ...[
                TextField(
                  controller: itemController,
                  decoration: const InputDecoration(labelText: 'Item/Drink Name'),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (RWF)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _addShoppingItem,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: Colors.green[700],
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Pay', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FutureBuilder<List<double>>(
                future: Future.wait([
                  _getCategoryBudget(),
                  _getTotalCategorySpent(),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final budget = snapshot.data![0];
                  final spent = snapshot.data![1];
                  final remaining = budget - spent;
                  final percentUsed = budget == 0 ? 0 : (spent / budget) * 100;
                  Color statusColor;
                  String statusText;
                  if (percentUsed >= 100) {
                    statusColor = Colors.red;
                    statusText = 'Budget exceeded!';
                  } else if (percentUsed >= 90) {
                    statusColor = Colors.orange;
                    statusText = 'Almost at budget!';
                  } else {
                    statusColor = Colors.green;
                    statusText = 'Within budget';
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$category Budget: RWF ${budget.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Total Spent: RWF ${budget > 0 ? spent.toStringAsFixed(2) : '0.00'}'),
                          Text('Remaining: RWF ${budget > 0 ? remaining.toStringAsFixed(2) : '0.00'}'),
                          Text(statusText, style: TextStyle(color: statusColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String prefix, String value, String label) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: $prefix$value'),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditSavingsGoalDialog(BuildContext context, double currentSavings) async {
    // Implementation of _showEditSavingsGoalDialog method
  }
} 