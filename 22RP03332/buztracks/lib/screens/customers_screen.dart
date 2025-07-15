import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _creditController = TextEditingController();
  
  String _searchQuery = '';
  bool _isAddingCustomer = false;
  int? _editingIndex;
  
  final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Listen to customers collection instead of sales
    _firestoreService.getCustomersStream().listen((customers) {
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((customer) {
      return customer['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer['phone'].toString().contains(_searchQuery) ||
             customer['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _addCustomer() {
    setState(() {
      _isAddingCustomer = true;
      _editingIndex = null;
    });
    _resetForm();
  }

  void _editCustomer(int index) {
    final customer = _filteredCustomers[index];
    setState(() {
      _isAddingCustomer = true;
      _editingIndex = _customers.indexOf(customer);
    });
    _nameController.text = customer['name'];
    _phoneController.text = customer['phone'];
    _emailController.text = customer['email'];
    _creditController.text = customer['credit'].toString();
  }

  void _deleteCustomer(int index) async {
    final customer = _filteredCustomers[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteCustomer),
        content: Text('${AppLocalizations.of(context)!.areYouSureYouWantToDelete} "${customer['name']}"?\n${AppLocalizations.of(context)!.thisWillAlsoDeleteAllTheirTransactionHistory}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.deleteCustomer(customer['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.customerDeleted)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'credit': int.tryParse(_creditController.text) ?? 0,
      'totalSpent': _editingIndex != null ? _customers[_editingIndex!]['totalSpent'] : 0,
      'lastPurchase': _editingIndex != null ? _customers[_editingIndex!]['lastPurchase'] : null,
      'transactions': _editingIndex != null ? _customers[_editingIndex!]['transactions'] : [],
    };

    setState(() {
      _isAddingCustomer = false;
    });

    if (_editingIndex != null) {
      // Update existing customer in Firestore
      final customerId = _customers[_editingIndex!]['id'];
      await _firestoreService.updateCustomer(customerId, customer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.customerUpdated)),
      );
    } else {
      // Add new customer to Firestore
      await _firestoreService.addCustomer(customer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.customerAdded)),
      );
    }

    _resetForm();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _creditController.clear();
  }

  void _showTransactionHistory(int index) {
    final customer = _filteredCustomers[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${customer['name']} - ${AppLocalizations.of(context)!.transactionHistory}'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.currentCredit),
                  Text('${customer['credit']} RWF', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.totalSpent),
                  Text('${customer['totalSpent']} RWF', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.recentTransactions, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: customer['transactions'].length,
                  itemBuilder: (context, idx) {
                    final transaction = customer['transactions'][idx];
                    return ListTile(
                      leading: Icon(
                        transaction['type'] == 'purchase' ? Icons.shopping_cart : Icons.payment,
                        color: transaction['type'] == 'purchase' ? Colors.red : Colors.green,
                      ),
                      title: Text('${transaction['type'] == 'purchase' ? AppLocalizations.of(context)!.purchase : AppLocalizations.of(context)!.payment}'),
                      subtitle: Text(transaction['date']),
                      trailing: Text(
                        '${transaction['type'] == 'purchase' ? '-' : '+'}${transaction['amount']} RWF',
                        style: TextStyle(
                          color: transaction['type'] == 'purchase' ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  void _updateCredit(int index) {
    final customer = _filteredCustomers[index];
    showDialog(
      context: context,
      builder: (context) {
        final creditController = TextEditingController(text: customer['credit'].toString());
        return AlertDialog(
          title: Text('${AppLocalizations.of(context)!.updateCreditFor} ${customer['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${AppLocalizations.of(context)!.currentCredit}: ${customer['credit']} RWF'),
              SizedBox(height: 16),
              TextField(
                controller: creditController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.of(context)!.newCreditAmount} (RWF)',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final newCredit = int.tryParse(creditController.text);
                if (newCredit != null) {
                  setState(() {
                    _customers[_customers.indexOf(customer)]['credit'] = newCredit;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppLocalizations.of(context)!.creditUpdatedTo} $newCredit RWF')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: mainColor),
              child: Text(AppLocalizations.of(context)!.update, style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.customers),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              final totalCustomers = _customers.length;
              final totalCredit = _customers.fold<int>(0, (sum, c) => sum + (c['credit'] as int));
              final totalSpent = _customers.fold<int>(0, (sum, c) => sum + (c['totalSpent'] as int));
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('${AppLocalizations.of(context)!.customerAnalytics}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLocalizations.of(context)!.totalCustomers}: $totalCustomers'),
                      Text('${AppLocalizations.of(context)!.totalCreditOutstanding}: $totalCredit RWF'),
                      Text('${AppLocalizations.of(context)!.totalRevenue}: $totalSpent RWF'),
                      SizedBox(height: 16),
                      Text('${AppLocalizations.of(context)!.topCustomers}', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._customers
                          .take(3)
                          .map((c) => Text('• ${c['name']}: ${c['totalSpent']} RWF')),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.close),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchCustomers,
                prefixIcon: Icon(Icons.search, color: mainColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Customer Form (when adding/editing)
          if (_isAddingCustomer)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mainColor),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingIndex != null ? AppLocalizations.of(context)!.editCustomer : AppLocalizations.of(context)!.addNewCustomer,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.customerName,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.person, color: mainColor),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterCustomerName;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.phoneNumber,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.phone, color: mainColor),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterPhoneNumber;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.emailOptional,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.email, color: mainColor),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _creditController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.initialCredit,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.account_balance_wallet, color: mainColor),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterCreditAmount;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveCustomer,
                            style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                            child: Text(AppLocalizations.of(context)!.save, style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isAddingCustomer = false;
                              });
                              _resetForm();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          // Customers List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading customers...'),
                      ],
                    ),
                  )
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? AppLocalizations.of(context)!.noCustomersYet : AppLocalizations.of(context)!.noCustomersFound,
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: Icon(Icons.add),
                                label: Text(AppLocalizations.of(context)!.addFirstCustomer),
                                style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                                onPressed: _addCustomer,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          final hasCredit = customer['credit'] > 0;
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasCredit ? Colors.orange : mainColor,
                                child: Icon(
                                  hasCredit ? Icons.account_balance_wallet : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                customer['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer['phone']),
                                  if (customer['email'].isNotEmpty)
                                    Text(customer['email'], style: TextStyle(color: Colors.grey[600])),
                                  Text(
                                    '${AppLocalizations.of(context)!.credit}: ${customer['credit']} RWF',
                                    style: TextStyle(
                                      color: hasCredit ? Colors.orange : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${AppLocalizations.of(context)!.totalSpent}: ${customer['totalSpent']} RWF',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.history),
                                      title: Text(AppLocalizations.of(context)!.transactionHistory),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () => _showTransactionHistory(index),
                                  ),
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text(AppLocalizations.of(context)!.edit),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () => _editCustomer(index),
                                  ),
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.account_balance_wallet),
                                      title: Text(AppLocalizations.of(context)!.updateCredit),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () => _updateCredit(index),
                                  ),
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () => _deleteCustomer(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        backgroundColor: mainColor,
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
} 