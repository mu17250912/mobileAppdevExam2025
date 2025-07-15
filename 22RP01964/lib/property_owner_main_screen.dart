import 'package:flutter/material.dart';
import 'theme.dart';
import 'property_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_property_screen.dart';
import 'edit_property_screen.dart';
import 'login_screen.dart'; // Added import for LoginScreen

class PropertyOwnerMainScreen extends StatefulWidget {
  const PropertyOwnerMainScreen({Key? key}) : super(key: key);

  @override
  State<PropertyOwnerMainScreen> createState() =>
      _PropertyOwnerMainScreenState();
}

class _PropertyOwnerMainScreenState extends State<PropertyOwnerMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    _OwnerHomeScreen(),
    _OwnerListingsScreen(),
    _OwnerWalletScreen(),
    _OwnerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _OwnerHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Stats
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('properties')
                    .where('ownerId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, propSnap) {
                  final totalProperties = propSnap.data?.docs.length ?? 0;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('ownerId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, txSnap) {
                      final txDocs = txSnap.data?.docs ?? [];
                      // Sort by createdAt descending in Dart
                      txDocs.sort((a, b) {
                        final aDate =
                            (a['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime(1970);
                        final bDate =
                            (b['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime(1970);
                        return bDate.compareTo(aDate);
                      });
                      final totalTransactions = txDocs.length;
                      final totalEarnings = txDocs.fold<double>(
                        0,
                        (sum, doc) => sum + (doc['ownerNet'] ?? 0),
                      );
                      final totalCommission = txDocs.fold<double>(
                        0,
                        (sum, doc) => sum + (doc['commission'] ?? 0),
                      );
                      final grossEarnings = txDocs.fold<double>(
                        0,
                        (sum, doc) => sum + (doc['amount'] ?? 0),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatCard(
                                label: 'Properties',
                                value: totalProperties.toString(),
                              ),
                              _StatCard(
                                label: 'Net Earnings',
                                value:
                                    'RWF ${totalEarnings.toStringAsFixed(0)}',
                              ),
                              _StatCard(
                                label: 'Transactions',
                                value: totalTransactions.toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatCard(
                                label: 'Gross Earnings',
                                value:
                                    'RWF ${grossEarnings.toStringAsFixed(0)}',
                                color: Colors.green[600]!,
                              ),
                              _StatCard(
                                label: 'Commission Paid',
                                value:
                                    'RWF ${totalCommission.toStringAsFixed(2)}',
                                color: Colors.orange[600]!,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          txDocs.isEmpty
                              ? const Text('No transactions yet.')
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: txDocs.length > 5
                                      ? 5
                                      : txDocs.length,
                                  itemBuilder: (context, index) {
                                    final tx = txDocs[index];
                                    final title =
                                        tx['propertyTitle'] ??
                                        tx['propertyId'] ??
                                        'Unknown Property';
                                    final amount = tx['amount'] ?? 0;
                                    final commission = tx['commission'] ?? 0;
                                    final ownerNet = tx['ownerNet'] ?? 0;
                                    final date = (tx['createdAt'] as Timestamp?)
                                        ?.toDate();
                                    final status = tx['status'] ?? '';
                                    final type = tx['type'] ?? 'rent';
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: type == 'rent'
                                                        ? kPrimaryColor
                                                              .withOpacity(0.1)
                                                        : Colors.green
                                                              .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    type.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: type == 'rent'
                                                          ? kPrimaryColor
                                                          : Colors.green[600],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Gross Amount',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        'RWF ${amount.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Commission (2%)',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        'RWF ${commission.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors
                                                              .orange[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Net Received',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        'RWF ${ownerNet.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color:
                                                              Colors.green[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                if (date != null)
                                                  Text(
                                                    'Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        status == 'rented' ||
                                                            status == 'sold'
                                                        ? Colors.green
                                                              .withOpacity(0.1)
                                                        : Colors.orange
                                                              .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    status[0].toUpperCase() +
                                                        status.substring(1),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          status == 'rented' ||
                                                              status == 'sold'
                                                          ? Colors.green[600]
                                                          : Colors.orange[600],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for stat cards
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color; // Added color parameter
  const _StatCard({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ), // Added color to text style
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerListingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .where('ownerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No properties found.'));
                }
                final properties = snapshot.data!.docs
                    .map(
                      (doc) => Property.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList();
                return ListView.builder(
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: property.imageUrl.isNotEmpty
                                  ? Image.network(
                                      property.imageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.home,
                                        color: Colors.grey,
                                        size: 48,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            // Details and badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          property.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Builder(
                                        builder: (context) {
                                          Color badgeColor;
                                          String badgeText;
                                          if (property.category.toLowerCase() ==
                                              'rent') {
                                            badgeColor = kPrimaryColor
                                                .withOpacity(0.92);
                                            badgeText = 'RENT';
                                          } else if (property.category
                                                  .toLowerCase() ==
                                              'sale') {
                                            badgeColor = Colors.green[600]!
                                                .withOpacity(0.92);
                                            badgeText = 'SALE';
                                          } else {
                                            badgeColor = Colors.grey
                                                .withOpacity(0.85);
                                            badgeText = property.category
                                                .toUpperCase();
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: badgeColor.withOpacity(
                                                    0.18,
                                                  ),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    property.address,
                                    style: const TextStyle(fontSize: 13.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'RWF ${property.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13.5),
                                  ),
                                  Text(
                                    'Status: ${property.status}',
                                    style: TextStyle(
                                      color: property.status == 'rented'
                                          ? Colors.red
                                          : Colors.green,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Actions
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditPropertyScreen(
                                          property: property,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Property'),
                                        content: const Text(
                                          'Are you sure you want to delete this property?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('properties')
                                          .doc(property.id)
                                          .delete();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Property deleted.'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          );
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add),
        tooltip: 'Add Property',
      ),
    );
  }
}

class _OwnerWalletScreen extends StatelessWidget {
  Future<void> _showSetWalletModal(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final _formKey = GlobalKey<FormState>();
    String provider = 'MTN';
    String walletNumber = '';
    bool isLoading = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Set Mobile Wallet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mobile Money Provider'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: provider,
                        items: const [
                          DropdownMenuItem(value: 'MTN', child: Text('MTN')),
                          DropdownMenuItem(
                            value: 'Airtel',
                            child: Text('Airtel'),
                          ),
                        ],
                        onChanged: (v) => setState(() => provider = v ?? 'MTN'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Wallet Number'),
                      const SizedBox(height: 6),
                      TextFormField(
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '07XXXXXXXX',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter wallet number'
                            : null,
                        onChanged: (v) => walletNumber = v,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                          label: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Wallet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;
                                  setState(() => isLoading = true);
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user!.uid)
                                      .set({
                                        'walletProvider': provider,
                                        'walletNumber': walletNumber,
                                      }, SetOptions(merge: true));
                                  setState(() => isLoading = false);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Wallet saved!'),
                                    ),
                                  );
                                },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blueGrey,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Used to receive payouts after bookings are confirmed.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _hasWallet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['walletProvider'] != null &&
        doc.data()?['walletNumber'] != null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<bool>(
      future: _hasWallet(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == false) {
          // Show modal on first time
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSetWalletModal(context);
          });
        }
        return Scaffold(
          appBar: AppBar(title: const Text('My Earnings')),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaction History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('ownerId', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      // Sort by createdAt descending in Dart
                      docs.sort((a, b) {
                        final aDate =
                            (a['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime(1970);
                        final bDate =
                            (b['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime(1970);
                        return bDate.compareTo(aDate);
                      });
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('No transactions found.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final tx = docs[index];
                          final title =
                              tx['propertyTitle'] ??
                              tx['propertyId'] ??
                              'Unknown Property';
                          final amount = tx['amount'] ?? 0;
                          final commission = tx['commission'] ?? 0;
                          final ownerNet = tx['ownerNet'] ?? 0;
                          final date = (tx['createdAt'] as Timestamp?)
                              ?.toDate();
                          final status = tx['status'] ?? '';
                          final type = tx['type'] ?? 'rent';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: type == 'rent'
                                              ? kPrimaryColor.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          type.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: type == 'rent'
                                                ? kPrimaryColor
                                                : Colors.green[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Gross Amount',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'RWF ${amount.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Commission (2%)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'RWF ${commission.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.orange[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Net Received',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'RWF ${ownerNet.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.green[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (date != null)
                                        Text(
                                          'Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              status == 'rented' ||
                                                  status == 'sold'
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          status[0].toUpperCase() +
                                              status.substring(1),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                status == 'rented' ||
                                                    status == 'sold'
                                                ? Colors.green[600]
                                                : Colors.orange[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OwnerProfileScreen extends StatefulWidget {
  @override
  State<_OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<_OwnerProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  String? _name;
  String? _email;
  String? _phone;
  String? _role;
  String? _walletProvider;
  String? _walletNumber;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};
    setState(() {
      _name = data['name'] ?? user.displayName ?? '';
      _email = data['email'] ?? user.email ?? '';
      _phone = data['phone'] ?? '';
      _role = data['role'] ?? '';
      _walletProvider = data['walletProvider'];
      _walletNumber = data['walletNumber'];
      _nameController.text = _name!;
      _phoneController.text = _phone!;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, SetOptions(merge: true));
    setState(() {
      _isEditing = false;
      _isLoading = false;
      _name = _nameController.text.trim();
      _phone = _phoneController.text.trim();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String currentPassword = '';
    String newPassword = '';
    final _formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter current password' : null,
                onChanged: (v) => currentPassword = v,
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Min 6 characters' : null,
                onChanged: (v) => newPassword = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              try {
                // Re-authenticate
                final cred = EmailAuthProvider.credential(
                  email: _email!,
                  password: currentPassword,
                );
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newPassword);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${e.toString()}')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: kPrimaryColor.withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _email ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (_role != null)
                              Text(
                                'Role: $_role',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.close : Icons.edit,
                          color: kPrimaryColor,
                        ),
                        onPressed: () =>
                            setState(() => _isEditing = !_isEditing),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_isEditing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              minimumSize: const Size.fromHeight(44),
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                  else ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone, color: kPrimaryColor),
                      title: const Text('Phone Number'),
                      subtitle: Text(_phone ?? '-'),
                    ),
                    if (_walletProvider != null && _walletNumber != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.account_balance_wallet,
                          color: kPrimaryColor,
                        ),
                        title: Text('Wallet ($_walletProvider)'),
                        subtitle: Text(_walletNumber ?? '-'),
                      ),
                  ],
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock, color: Colors.orange),
                    title: const Text('Change Password'),
                    onTap: _changePassword,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
