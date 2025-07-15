import 'package:flutter/material.dart';
import '../firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoanManagementScreen extends StatefulWidget {
  @override
  _LoanManagementScreenState createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
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
      final loans = await _firestoreService.getLoans();
      final borrowers = await _firestoreService.getBorrowers();
      
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7B8AFF),
      appBar: AppBar(
        backgroundColor: Color(0xFF7B8AFF),
        elevation: 0,
        title: Text('Loan Management', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
          ),
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
                    child: _loans.isEmpty
                        ? _buildEmptyState()
                        : _buildLoansList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: Color(0xFF7B8AFF)),
        onPressed: () => _showAddLoanDialog(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    double totalLoaned = 0;
    double totalCollected = 0;
    
    for (var loan in _loans) {
      totalLoaned += (loan['amount'] ?? 0.0);
      totalCollected += (loan['totalPaid'] ?? 0.0);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Loaned',
              '\$${totalLoaned.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              Colors.green,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Collected',
              '\$${totalCollected.toStringAsFixed(2)}',
              Icons.payment,
              Colors.blue,
            ),
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No loans yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first loan to get started',
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
            onPressed: () => _showAddLoanDialog(),
            child: Text('Add Loan'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _loans.length,
      itemBuilder: (context, index) {
        final loan = _loans[index];
        final borrower = _borrowers.firstWhere(
          (b) => b['id'] == loan['borrowerId'],
          orElse: () => {'fullName': 'Unknown Borrower'},
        );

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(
              borrower['fullName'] ?? 'Unknown Borrower',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text('Amount: \$${(loan['amount'] ?? 0.0).toStringAsFixed(2)}'),
                Text('Remaining: \$${(loan['remainingAmount'] ?? 0.0).toStringAsFixed(2)}'),
                Text('Status: ${loan['status'] ?? 'active'}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
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
                  value: 'payments',
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 16),
                      SizedBox(width: 8),
                      Text('View Payments'),
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
                  case 'edit':
                    _showEditLoanDialog(loan);
                    break;
                  case 'payments':
                    _showPaymentsDialog(loan);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(loan);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddLoanDialog() {
    final borrowerController = TextEditingController();
    final amountController = TextEditingController();
    final interestController = TextEditingController();
    final termController = TextEditingController();
    String? selectedBorrowerId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Loan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedBorrowerId,
                hint: Text('Select Borrower'),
                items: _borrowers.map((borrower) {
                  return DropdownMenuItem<String>(
                    value: borrower['id'],
                    child: Text(borrower['fullName']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedBorrowerId = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Loan Amount',
                  prefixText: '\$',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: interestController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Interest Rate (%)',
                  suffixText: '%',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: termController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Term (months)',
                  suffixText: 'months',
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
              if (selectedBorrowerId != null &&
                  amountController.text.isNotEmpty) {
                final loanData = {
                  'borrowerId': selectedBorrowerId,
                  'amount': double.parse(amountController.text),
                  'interestRate': double.tryParse(interestController.text) ?? 0.0,
                  'term': int.tryParse(termController.text) ?? 12,
                };

                try {
                  await _firestoreService.addLoan(loanData);
                  // Add notification for new loan
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'userId': user.uid,
                        'title': 'New Loan Created',
                        'body': 'A new loan has been added to your account.',
                        'category': 'Loans',
                        'timestamp': DateTime.now(),
                        'read': false,
                      });
                      print('Notification for new loan created for user: ${user.uid}');
                    } catch (notifError) {
                      print('Failed to create notification: ${notifError.toString()}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Loan added, but notification failed: ${notifError.toString()}')),
                      );
                    }
                  }
                  Navigator.of(context).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Loan added successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding loan: ${e.toString()}')),
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

  void _showEditLoanDialog(Map<String, dynamic> loan) {
    // Implementation for editing loan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _showPaymentsDialog(Map<String, dynamic> loan) {
    // Implementation for viewing payments
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payments view coming soon!')),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Loan'),
        content: Text('Are you sure you want to delete this loan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _firestoreService.updateLoan(loan['id'], {'status': 'deleted'});
                Navigator.of(context).pop();
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Loan deleted successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting loan: $e')),
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

// Placeholder for MessagesScreen
class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
          ),
        ],
        backgroundColor: Color(0xFF7B8AFF),
        elevation: 0,
      ),
      body: Center(child: Text('Messages coming soon!')),
    );
  }
}  