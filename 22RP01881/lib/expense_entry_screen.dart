import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'premium_upgrade_dialog.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  int selectedMonth = 1;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  List<String> _defaultCategories = [
    'Food', 'Rent', 'Transport', 'Electricity', 'School Fees', 'Other',
  ];
  List<String> _customCategories = [];
  final Map<String, String> _nameToCategory = {
    'food': 'Food',
    'rent': 'Rent',
    'transport': 'Transport',
    'electricity': 'Electricity',
    'school': 'School Fees',
    'shoes': 'Other',
  };

  Future<bool> _isPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists && (doc.data()?['isPremium'] ?? false);
  }

  void _addCategory() async {
    final controller = TextEditingController();
    final isPremium = await _isPremium();
    if (!isPremium && _customCategories.length >= 5) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Upgrade to Premium'),
          content: const Text('Free users can only have 5 custom categories. Upgrade to premium for unlimited categories.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.showPremiumUpgradeDialog(
                  featureName: 'Unlimited Categories',
                  customMessage: 'Free users can only have 5 custom categories. Upgrade to premium for unlimited categories.',
                );
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newCat = controller.text.trim();
              if (newCat.isNotEmpty && !_customCategories.contains(newCat) && !_defaultCategories.contains(newCat)) {
                setState(() {
                  _customCategories.add(newCat);
                  _selectedCategory = newCat;
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final allCategories = [..._defaultCategories, ..._customCategories, 'Add Category'];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'SmartBudget',
          style: GoogleFonts.poppins(
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Remove or comment out the logo image container
              // Container(
              //   decoration: BoxDecoration(
              //     color: Theme.of(context).cardColor,
              //     shape: BoxShape.circle,
              //     boxShadow: [
              //       BoxShadow(
              //         color: Theme.of(context).shadowColor.withOpacity(0.1),
              //         blurRadius: 4,
              //         offset: Offset(0, 2),
              //       ),
              //     ],
              //   ),
              //   child: Padding(
              //     padding: const EdgeInsets.all(12.0),
              //     child: Image.asset(
              //       'assets/smartbudget_logo.png',
              //       height: 60,
              //       width: 60,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 18),
              Text(
                'Add Expense',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.poppins(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: GoogleFonts.poppins(),
                            filled: true,
                            fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: Icon(Icons.edit, color: Theme.of(context).colorScheme.error),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter name';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final lower = value.toLowerCase();
                            for (final entry in _nameToCategory.entries) {
                              if (lower.contains(entry.key)) {
                                setState(() {
                                  _selectedCategory = entry.value;
                                });
                                break;
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: GoogleFonts.poppins(),
                            filled: true,
                            fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: Icon(Icons.category, color: Theme.of(context).colorScheme.error),
                          ),
                          items: allCategories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val == 'Add Category') {
                              _addCategory();
                            } else {
                              setState(() => _selectedCategory = val);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty || value == 'Add Category') {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _amountController,
                          style: GoogleFonts.poppins(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            labelText: 'Amount (FRW)',
                            labelStyle: GoogleFonts.poppins(),
                            filled: true,
                            fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.error),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _dateController,
                          style: GoogleFonts.poppins(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            labelText: 'Date',
                            labelStyle: GoogleFonts.poppins(),
                            filled: true,
                            fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: Icon(Icons.date_range, color: Theme.of(context).colorScheme.error),
                          ),
                          readOnly: true,
                          onTap: () async {
                            FocusScope.of(context).requestFocus(FocusNode());
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              _dateController.text = picked.toString().split(' ')[0];
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: width * 0.7,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              foregroundColor: Theme.of(context).colorScheme.onError,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: 1.2,
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // Save expense to Firestore
                                final name = _nameController.text.trim();
                                final category = _selectedCategory ?? '';
                                final amount = _amountController.text.trim();
                                final date = _dateController.text.trim();
                                await FirebaseFirestore.instance.collection('expenses').add({
                                  'name': name,
                                  'category': category,
                                  'amount': amount,
                                  'date': date,
                                });
                                // Also save to transactions collection
                                await FirebaseFirestore.instance.collection('transactions').add({
                                  'type': 'Expense',
                                  'amount': amount,
                                  'date': date,
                                  'category': category,
                                  'name': name,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Expense saved!')),
                                );
                                _nameController.clear();
                                _amountController.clear();
                                _dateController.clear();
                                // Redirect to dashboard
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => DashboardScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text('Add Expense'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 