import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isSaving = false;
  String? _editingBudgetId; // To track which budget is being edited
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _addBudget() async {
    if (currentUser == null) return;
    final category = _categoryController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final date = _selectedDate;
    if (category.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a category.')),
        );
      }
      return;
    }
    if (amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount greater than 0.')),
        );
      }
      return;
    }
    if (date == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date.')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final budgetsRef = FirebaseFirestore.instance
          .collection('budgets')
          .doc(currentUser!.uid)
          .collection('user_budgets');

      if (_editingBudgetId != null) {
        // Update existing budget
        await budgetsRef.doc(_editingBudgetId).update({
          'category': category,
          'amount': amount,
          'date': date,
          'month': _selectedMonth,
          'year': _selectedYear,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Budget for "$category" updated!')),
          );
        }
      } else {
        // Check if a budget with this category already exists before adding new
        final querySnapshot = await budgetsRef
          .where('category', isEqualTo: category)
          .where('month', isEqualTo: _selectedMonth)
          .where('year', isEqualTo: _selectedYear)
          .limit(1)
          .get();
        if (querySnapshot.docs.isNotEmpty) {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Budget for "$category" already exists for this month. Please update it instead.')),
            );
          }
        } else {
            // Add new budget
          await budgetsRef.add({
            'category': category,
            'amount': amount,
            'date': date,
            'month': _selectedMonth,
            'year': _selectedYear,
            'created_at': FieldValue.serverTimestamp(),
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Budget for "$category" added!')),
            );
          }
        }
      }

      _clearForm();
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save budget: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _startEditing(DocumentSnapshot budget) {
    _editingBudgetId = budget.id;
    _categoryController.text = budget['category'];
    _amountController.text = budget['amount'].toString();
    final date = (budget['date'] as Timestamp).toDate();
    _selectedDate = date;
    _dateController.text = DateFormat('dd/MM/yyyy').format(date);
    setState(() {}); // To update the button text
  }

  void _clearForm() {
    _editingBudgetId = null;
    _categoryController.clear();
    _amountController.clear();
    _dateController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'BUDGET',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month/Year Pickers
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      items: List.generate(12, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(DateFormat.MMMM().format(DateTime(0, index + 1))),
                      )),
                      onChanged: (val) => setState(() => _selectedMonth = val!),
                      decoration: const InputDecoration(labelText: 'Month'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      items: List.generate(5, (index) {
                        int year = DateTime.now().year - 2 + index;
                        return DropdownMenuItem(value: year, child: Text('$year'));
                      }),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Budget Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _BudgetTable(
                  currentUser: currentUser,
                  onEdit: _startEditing,
                  month: _selectedMonth,
                  year: _selectedYear,
                ),
              ),
              const SizedBox(height: 16),
              if (_editingBudgetId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Editing Budget',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                      ),
                      TextButton(
                        onPressed: _clearForm,
                        child: const Text('Cancel Edit'),
                      )
                    ],
                  ),
                ),
              const Text(
                'Category_name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Budget_amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _addBudget,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(_editingBudgetId != null ? 'Update' : 'Save', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetTable extends StatefulWidget {
  final User? currentUser;
  final Function(DocumentSnapshot) onEdit;
  final int month;
  final int year;

  const _BudgetTable({required this.currentUser, required this.onEdit, required this.month, required this.year});

  @override
  State<_BudgetTable> createState() => _BudgetTableState();
}

class _BudgetTableState extends State<_BudgetTable> {
  Future<void> _deleteBudget(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('budgets')
            .doc(widget.currentUser!.uid)
            .collection('user_budgets')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget deleted successfully')),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete budget: ${e.message}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Not logged in.'),
      );
    }
    final budgetsRef = FirebaseFirestore.instance
        .collection('budgets')
        .doc(widget.currentUser!.uid)
        .collection('user_budgets');
    return StreamBuilder<QuerySnapshot>(
      stream: budgetsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No budgets yet.'),
          );
        }
        // Filter docs by month/year, fallback to date if fields missing
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('month') && data.containsKey('year')) {
            return data['month'] == widget.month && data['year'] == widget.year;
          } else if (data['date'] != null) {
            final date = (data['date'] as Timestamp).toDate();
            return date.month == widget.month && date.year == widget.year;
          }
          return false;
        }).toList();
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No budgets yet.'),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Id')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Budget')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Actions')),
            ],
            rows: docs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;
              final date = data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : null;
              return DataRow(cells: [
                DataCell(Text((index + 1).toString())),
                DataCell(Text(data['category'] ?? '')),
                DataCell(Text(data['amount']?.toString() ?? '')),
                DataCell(Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : '')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => widget.onEdit(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBudget(doc.id),
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
} 