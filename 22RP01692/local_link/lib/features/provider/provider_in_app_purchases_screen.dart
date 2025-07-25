import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProviderInAppPurchasesScreen extends StatefulWidget {
  const ProviderInAppPurchasesScreen({super.key});

  @override
  State<ProviderInAppPurchasesScreen> createState() => _ProviderInAppPurchasesScreenState();
}

class _ProviderInAppPurchasesScreenState extends State<ProviderInAppPurchasesScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> _virtualGoods = [
    {
      'id': 'boost_1',
      'name': 'Profile Boost',
      'description': 'Increase your profile visibility for 7 days',
      'price': 5000,
      'currency': 'FRW',
      'duration': '7 days',
      'icon': Icons.trending_up,
      'color': Colors.orange,
      'category': 'marketing',
    },
    {
      'id': 'boost_2',
      'name': 'Premium Profile Boost',
      'description': 'Maximum profile visibility for 30 days',
      'price': 15000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.star,
      'color': Colors.amber,
      'category': 'marketing',
    },
    {
      'id': 'sms_pack_1',
      'name': 'SMS Pack (100)',
      'description': 'Send 100 SMS notifications to customers',
      'price': 8000,
      'currency': 'FRW',
      'count': 100,
      'icon': Icons.sms,
      'color': Colors.blue,
      'category': 'communication',
    },
    {
      'id': 'sms_pack_2',
      'name': 'SMS Pack (500)',
      'description': 'Send 500 SMS notifications to customers',
      'price': 35000,
      'currency': 'FRW',
      'count': 500,
      'icon': Icons.sms,
      'color': Colors.blue,
      'category': 'communication',
    },
    {
      'id': 'analytics_1',
      'name': 'Advanced Analytics',
      'description': 'Unlock advanced analytics for 30 days',
      'price': 12000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.analytics,
      'color': Colors.purple,
      'category': 'analytics',
    },
    {
      'id': 'custom_branding',
      'name': 'Custom Branding',
      'description': 'Add your logo and custom colors for 30 days',
      'price': 25000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.palette,
      'color': Colors.green,
      'category': 'branding',
    },
    {
      'id': 'priority_support',
      'name': 'Priority Support',
      'description': 'Get priority customer support for 30 days',
      'price': 20000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.support_agent,
      'color': Colors.red,
      'category': 'support',
    },
    {
      'id': 'api_access',
      'name': 'API Access',
      'description': 'Access to our API for 30 days',
      'price': 40000,
      'currency': 'FRW',
      'duration': '30 days',
      'icon': Icons.api,
      'color': Colors.indigo,
      'category': 'development',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a provider.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('In-App Purchases'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final balance = (userData['virtualBalance'] ?? 0).toDouble();
                final smsCredits = userData['smsCredits'] ?? 0;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Virtual Balance',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              '${balance.toInt()} FRW',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.sms, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              '$smsCredits SMS Credits',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddBalanceDialog(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Balance'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showPurchaseHistory(context),
                                icon: const Icon(Icons.history),
                                label: const Text('History'),
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
            const SizedBox(height: 24),

            // Categories
            const Text(
              'Available Purchases',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Category Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All', true),
                  _buildCategoryChip('Marketing', false),
                  _buildCategoryChip('Communication', false),
                  _buildCategoryChip('Analytics', false),
                  _buildCategoryChip('Branding', false),
                  _buildCategoryChip('Support', false),
                  _buildCategoryChip('Development', false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Virtual Goods Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _virtualGoods.length,
              itemBuilder: (context, index) {
                final item = _virtualGoods[index];
                return _buildVirtualGoodCard(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          // Implement category filtering
        },
      ),
    );
  }

  Widget _buildVirtualGoodCard(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final description = item['description'] as String;
    final price = item['price'] as double;
    final currency = item['currency'] as String;
    final icon = item['icon'] as IconData;
    final color = item['color'] as Color;
    final duration = item['duration'] as String?;
    final count = item['count'] as int?;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$currency ${price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (duration != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Duration: $duration',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            if (count != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Count: $count',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPurchaseDialog(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'Purchase',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBalanceDialog(BuildContext context) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Virtual Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add funds to your virtual balance for in-app purchases.'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (FRW)',
                prefixText: '',
                hintText: '10000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                await _addVirtualBalance(amount);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${item['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to purchase:'),
            const SizedBox(height: 8),
            Text(
              item['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(item['description']),
            const SizedBox(height: 8),
            Text(
              'Price: ${item['price'].toInt()} ${item['currency']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (item['duration'] != null)
              Text('Duration: ${item['duration']}'),
            if (item['count'] != null)
              Text('Count: ${item['count']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processPurchase(item);
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('purchases')
                .where('userId', isEqualTo: user!.uid)
                .orderBy('purchaseDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final purchases = snapshot.data!.docs;
              
              if (purchases.isEmpty) {
                return const Center(child: Text('No purchase history'));
              }

              return ListView.builder(
                itemCount: purchases.length,
                itemBuilder: (context, index) {
                  final purchase = purchases[index].data() as Map<String, dynamic>;
                  final itemName = purchase['itemName'] ?? '';
                  final amount = purchase['amount'] ?? 0.0;
                  final date = (purchase['purchaseDate'] as Timestamp?)?.toDate();
                  
                  return ListTile(
                    title: Text(itemName),
                    subtitle: date != null ? Text(DateFormat('MMM dd, yyyy').format(date)) : null,
                    trailing: Text('${amount.toInt()} FRW'),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _addVirtualBalance(double amount) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'virtualBalance': FieldValue.increment(amount),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ${amount.toInt()} FRW to your balance'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding balance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processPurchase(Map<String, dynamic> item) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final currentBalance = (userData['virtualBalance'] ?? 0).toDouble();
      final itemPrice = item['price'] as double;

      if (currentBalance < itemPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient balance. Please add more funds.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Deduct balance
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'virtualBalance': FieldValue.increment(-itemPrice),
      });

      // Add SMS credits if applicable
      if (item['id'].toString().contains('sms_pack')) {
        final smsCount = item['count'] as int;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'smsCredits': FieldValue.increment(smsCount),
        });
      }

      // Record purchase
      await FirebaseFirestore.instance
          .collection('purchases')
          .add({
        'userId': user!.uid,
        'itemId': item['id'],
        'itemName': item['name'],
        'amount': itemPrice,
        'currency': item['currency'],
        'purchaseDate': FieldValue.serverTimestamp(),
        'duration': item['duration'],
        'count': item['count'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased ${item['name']}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing purchase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 