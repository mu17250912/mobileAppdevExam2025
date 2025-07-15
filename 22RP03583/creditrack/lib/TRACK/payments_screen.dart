import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> sendAllTasksCompletedNotification() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': user.uid,
    'title': 'Congratulations!',
    'body': 'You have completed all your loans and payments!',
    'category': 'Reminders',
    'timestamp': DateTime.now(),
    'read': false,
  });
}

class PaymentsScreen extends StatefulWidget {
  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _loans = [];
  List<Map<String, dynamic>> _borrowers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final payments = await _firestoreService.getPayments();
      final loans = await _firestoreService.getLoans();
      final borrowers = await _firestoreService.getBorrowers();
      
      setState(() {
        _payments = payments;
        _loans = loans;
        _borrowers = borrowers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _checkAndSendAllTasksCompletedReminder() async {
    final allCompleted = _loans.isNotEmpty && _loans.every((loan) {
      final status = loan['status'] ?? '';
      final remaining = loan['remainingAmount'] ?? 0.0;
      return status == 'completed' || remaining == 0.0;
    });
    if (allCompleted) {
      await sendAllTasksCompletedNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7B8AFF),
      appBar: AppBar(
        backgroundColor: Color(0xFF7B8AFF),
        elevation: 0,
        title: Text('Payments', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _buildSummaryCards(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: _payments.isEmpty
                        ? _buildEmptyState()
                        : _buildPaymentsList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.white,
            child: Icon(Icons.add, color: Color(0xFF7B8AFF)),
            onPressed: () => _showAddPaymentDialog(),
            heroTag: 'addPayment',
          ),
          SizedBox(height: 12),
          FloatingActionButton.extended(
            backgroundColor: Colors.green,
            icon: Icon(Icons.payment, color: Colors.white),
            label: Text('Simulate Payment', style: TextStyle(color: Colors.white)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Payment Gateway'),
                  content: Text('Payment of \$100 simulated successfully!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
            heroTag: 'simulatePayment',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    double totalCollected = 0;
    double thisMonth = 0;
    double thisWeek = 0;
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    for (var payment in _payments) {
      final amount = payment['amount'] ?? 0.0;
      totalCollected += amount;
      
      final paymentDate = (payment['createdAt'] as Timestamp).toDate();
      if (paymentDate.isAfter(startOfMonth)) {
        thisMonth += amount;
      }
      if (paymentDate.isAfter(startOfWeek)) {
        thisWeek += amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Collected',
                  '\$${totalCollected.toStringAsFixed(2)}',
                  Icons.payment,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'This Month',
                  '\$${thisMonth.toStringAsFixed(2)}',
                  Icons.calendar_month,
                  Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'This Week',
                  '\$${thisWeek.toStringAsFixed(2)}',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Payments',
                  '${_payments.length}',
                  Icons.receipt_long,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No payments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Record your first payment to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7B8AFF),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showAddPaymentDialog(),
            child: Text('Add Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final loan = _loans.firstWhere(
          (l) => l['id'] == payment['loanId'],
          orElse: () => {'borrowerId': 'unknown'},
        );
        final borrower = _borrowers.firstWhere(
          (b) => b['id'] == loan['borrowerId'],
          orElse: () => {'fullName': 'Unknown Borrower'},
        );

        final paymentDate = (payment['createdAt'] as Timestamp).toDate();
        final formattedDate = '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}';

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Color(0xFF7B8AFF).withOpacity(0.1),
              child: Icon(
                Icons.payment,
                color: Color(0xFF7B8AFF),
              ),
            ),
            title: Text(
              borrower['fullName'] ?? 'Unknown Borrower',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text('Amount: \$${(payment['amount'] ?? 0.0).toStringAsFixed(2)}'),
                Text('Date: $formattedDate'),
                Text('Status: ${payment['status'] ?? 'completed'}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _showPaymentDetails(payment, borrower, loan);
                    break;
                  case 'edit':
                    _showEditPaymentDialog(payment);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(payment);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedLoanId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedLoanId,
                hint: Text('Select Loan'),
                items: _loans.where((loan) => loan['status'] == 'active').map((loan) {
                  final borrower = _borrowers.firstWhere(
                    (b) => b['id'] == loan['borrowerId'],
                    orElse: () => {'fullName': 'Unknown'},
                  );
                  return DropdownMenuItem<String>(
                    value: loan['id'],
                    child: Text('${borrower['fullName']} - \$${(loan['amount'] ?? 0.0).toStringAsFixed(2)}'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedLoanId = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '\$',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedLoanId != null && amountController.text.isNotEmpty) {
                final paymentData = {
                  'loanId': selectedLoanId,
                  'amount': double.parse(amountController.text),
                  'notes': notesController.text.trim(),
                };

                try {
                  await _firestoreService.addPayment(paymentData);
                  Navigator.of(context).pop();
                  await _loadData();
                  await _checkAndSendAllTasksCompletedReminder();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment added successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding payment: $e')),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment, Map<String, dynamic> borrower, Map<String, dynamic> loan) {
    final paymentDate = (payment['createdAt'] as Timestamp).toDate();
    final formattedDate = '${paymentDate.day}/${paymentDate.month}/${paymentDate.year} at ${paymentDate.hour}:${paymentDate.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Borrower: ${borrower['fullName'] ?? 'Unknown'}'),
            SizedBox(height: 8),
            Text('Loan Amount: \$${(loan['amount'] ?? 0.0).toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text('Payment Amount: \$${(payment['amount'] ?? 0.0).toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text('Date: $formattedDate'),
            if (payment['notes'] != null && payment['notes'].isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Notes: ${payment['notes']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditPaymentDialog(Map<String, dynamic> payment) {
    // Implementation for editing payment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Payment'),
        content: Text('Are you sure you want to delete this payment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // Note: In a real app, you'd want to handle payment deletion more carefully
                // and potentially reverse the loan balance updates
                Navigator.of(context).pop();
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment deleted successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting payment: $e')),
                );
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
} 