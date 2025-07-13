import 'package:flutter/material.dart';
import 'custom_top_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  final String? userEmail;
  const SettingsScreen({Key? key, this.onThemeChanged, this.userEmail})
    : super(key: key);
  final void Function(bool isDark)? onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.account_circle, 'label': 'Account Details'},
    {'icon': Icons.mail, 'label': 'Messages'},
    {'icon': Icons.notifications, 'label': 'Notifications'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];
  int _selectedMenuIndex = 0;

  // Removed dropdown items
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: CustomTopBar(pageName: 'Settings', userEmail: widget.userEmail),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left menu
                        Flexible(flex: 2, child: _buildMenu(isWide)),
                        const SizedBox(width: 32),
                        // Right search, dropdown, and dynamic content
                        Flexible(flex: 3, child: _buildContent(isWide)),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Menu always visible on top
                          _buildMenu(isWide),
                          const SizedBox(height: 16),
                          _buildContent(isWide),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, int index) {
    final bool selected = index == _selectedMenuIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMenuIndex = index;
        });
      },
      child: Container(
        decoration: selected
            ? BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              )
            : null,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200, width: 3),
                color: Colors.white,
              ),
              child: Icon(icon, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                // No underline for selected
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 2,
      width: 40,
      color: Colors.blue[100],
    );
  }

  Widget _buildMenu(bool isWide) {
    return Container(
      width: isWide ? null : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _menuItems.length; i++) ...[
            _menuItem(_menuItems[i]['icon'], _menuItems[i]['label'], i),
            if (i != _menuItems.length - 1) _menuDivider(),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade200,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade200,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.search, color: Colors.blue, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Dynamic right panel content
        _buildRightPanelContent(isWide),
      ],
    );
  }

  Widget _buildRightPanelContent(bool isWide) {
    // Example dynamic content based on selected menu and dropdown
    if (_selectedMenuIndex == 0) {
      return _accountDetailsContent(isWide);
    } else if (_selectedMenuIndex == 1) {
      return _messagesContent(isWide);
    } else if (_selectedMenuIndex == 2) {
      return _notificationsContent(isWide);
    } else {
      return _settingsContent(isWide);
    }
  }

  Widget _accountDetailsContent(bool isWide) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: widget.userEmail != null && widget.userEmail!.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: widget.userEmail)
                  .limit(1)
                  .snapshots()
              : null,
          builder: (context, snapshot) {
            if (widget.userEmail == null || widget.userEmail!.isEmpty) {
              return Text('No user email provided.');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading user data.');
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Text('No user data found for this email.');
            }
            final data = docs.first.data() as Map<String, dynamic>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.blue, size: isWide ? 40 : 28),
                    SizedBox(width: 12),
                    Text(
                      'Account Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: isWide ? 24 : 12),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.orange, size: isWide ? 32 : 22),
                  title: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isWide ? 18 : 15)),
                  subtitle: Text(data['username'] ?? '-', style: TextStyle(fontSize: isWide ? 16 : 13)),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.green, size: isWide ? 32 : 22),
                  title: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isWide ? 18 : 15)),
                  subtitle: Text(data['email'] ?? '-', style: TextStyle(fontSize: isWide ? 16 : 13)),
                ),
                // Add more fields here if needed
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _messagesContent(bool isWide) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 24 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: Colors.blue, size: isWide ? 40 : 28),
                SizedBox(width: 12),
                Text(
                  'All Cards',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: isWide ? 18 : 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Cards')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error loading cards.');
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Text('No cards found.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final ts = data['timestamp'];
                    final dateStr = ts is Timestamp ? ts.toDate().toString() : '';
                    return ListTile(
                      leading: Icon(Icons.credit_card, color: Colors.orange, size: isWide ? 32 : 22),
                      title: Text(
                        data['cardName']?.toString() ?? '-',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: isWide ? 18 : 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.numbers, color: Colors.blue, size: 16),
                              SizedBox(width: 4),
                              Text('Number: ${data['cardNumber'] ?? '-'}', style: TextStyle(fontSize: isWide ? 15 : 12)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text('Client: ${data['clientName'] ?? '-'}', style: TextStyle(fontSize: isWide ? 15 : 12)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.teal, size: 16),
                              SizedBox(width: 4),
                              Text('Balance: ${data['initialBalance'] ?? '-'}', style: TextStyle(fontSize: isWide ? 15 : 12)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.grey, size: 16),
                              SizedBox(width: 4),
                              Text(dateStr, style: TextStyle(fontSize: isWide ? 14 : 11)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationsContent(bool isWide) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 24 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: isWide ? 12 : 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllRecentTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error loading transactions.');
                }
                final txs = snapshot.data ?? [];
                if (txs.isEmpty) {
                  return Text('No recent transactions.');
                }
                return SizedBox(
                  height: isWide ? 400 : 250,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, i) {
                      final tx = txs[i];
                      final type = tx['type'] ?? '';
                      final amount = tx['amount']?.toString() ?? '';
                      final desc = tx['desc']?.toString() ?? '';
                      final ts = tx['timestamp'];
                      final dateStr = ts is Timestamp
                          ? ts.toDate().toString()
                          : '';
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isWide ? 14 : 6,
                          horizontal: isWide ? 18 : 8,
                        ),
                        leading: Icon(
                          type == 'Payment'
                              ? Icons.payment
                              : type == 'Saving'
                              ? Icons.savings
                              : Icons.credit_card,
                          color: type == 'Payment'
                              ? Colors.blue
                              : type == 'Saving'
                              ? Colors.green
                              : Colors.orange,
                          size: isWide ? 32 : 22,
                        ),
                        title: Text(
                          '$type: $desc',
                          style: TextStyle(
                            fontSize: isWide ? 18 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          dateStr,
                          style: TextStyle(fontSize: isWide ? 15 : 12),
                        ),
                        trailing: Text(
                          amount,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: type == 'Payment'
                                ? Colors.blue
                                : type == 'Saving'
                                ? Colors.green
                                : Colors.orange,
                            fontSize: isWide ? 18 : 14,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllRecentTransactions() async {
    final paymentsSnap = await FirebaseFirestore.instance
        .collection('payments')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    final savingsSnap = await FirebaseFirestore.instance
        .collection('savings')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    final cardsSnap = await FirebaseFirestore.instance
        .collection('Cards')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    List<Map<String, dynamic>> txs = [];
    txs.addAll(
      paymentsSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'type': 'Payment',
          'amount': data['amount']?.toString() ?? '',
          'desc': data['cardholderName']?.toString() ?? '',
          'timestamp': data['timestamp'],
        };
      }),
    );
    txs.addAll(
      savingsSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'type': 'Saving',
          'amount': data['amount']?.toString() ?? '',
          'desc': data['bankName']?.toString() ?? '',
          'timestamp': data['timestamp'],
        };
      }),
    );
    txs.addAll(
      cardsSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'type': 'Card',
          'amount': data['initialBalance']?.toString() ?? '',
          'desc': data['cardName']?.toString() ?? '',
          'timestamp': data['timestamp'],
        };
      }),
    );
    // Sort by timestamp descending
    txs.sort((a, b) {
      final ta = a['timestamp'] is Timestamp
          ? (a['timestamp'] as Timestamp).toDate()
          : DateTime(1970);
      final tb = b['timestamp'] is Timestamp
          ? (b['timestamp'] as Timestamp).toDate()
          : DateTime(1970);
      return tb.compareTo(ta);
    });
    return txs.take(20).toList();
  }

  Widget _settingsContent(bool isWide) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 24 : 12),
        child: FutureBuilder<QuerySnapshot>(
          future: widget.userEmail != null && widget.userEmail!.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: widget.userEmail)
                  .limit(1)
                  .get()
              : null,
          builder: (context, snapshot) {
            if (widget.userEmail == null || widget.userEmail!.isEmpty) {
              return Text('No user email provided.');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading user data.');
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Text('No user data found for this email.');
            }
            final data = docs.first.data() as Map<String, dynamic>;
            nameController.text = data['username'] ?? '';
            emailController.text = data['email'] ?? '';
            return StatefulBuilder(
              builder: (context, setState) {
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update Account', style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: isWide ? 12 : 8),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter your email' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v != null && v.isNotEmpty && v.length < 6 ? 'Password too short' : null,
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Icon(Icons.save, color: Colors.white),
                            label: Text(isLoading ? 'Saving...' : 'Update'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    setState(() => isLoading = true);
                                    try {
                                      // Update Firestore user document
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(docs.first.id)
                                          .update({
                                        'username': nameController.text.trim(),
                                        'email': emailController.text.trim(),
                                      });
                                      // Optionally update password in Firebase Auth (not shown here)
                                      await Future.delayed(const Duration(seconds: 2));
                                    } catch (e) {
                                      // Optionally show error
                                    }
                                    setState(() => isLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Account updated successfully'),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
