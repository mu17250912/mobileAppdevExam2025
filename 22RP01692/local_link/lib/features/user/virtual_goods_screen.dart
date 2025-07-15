import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VirtualGoodsScreen extends StatefulWidget {
  const VirtualGoodsScreen({super.key});

  @override
  State<VirtualGoodsScreen> createState() => _VirtualGoodsScreenState();
}

class _VirtualGoodsScreenState extends State<VirtualGoodsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> _virtualGoods = [
    {
      'id': 'booking_boost',
      'name': 'Booking Boost',
      'description': 'Increase your booking success rate by 50%',
      'price': 2.99,
      'currency': 'USD',
      'duration': '7 days',
      'icon': Icons.rocket_launch,
      'color': Colors.red,
      'category': 'boost',
      'quantity': 1,
    },
    {
      'id': 'priority_ticket',
      'name': 'Priority Ticket',
      'description': 'Skip the queue and get instant service',
      'price': 4.99,
      'currency': 'USD',
      'duration': '1 use',
      'icon': Icons.confirmation_number,
      'color': Colors.orange,
      'category': 'ticket',
      'quantity': 1,
    },
    {
      'id': 'service_credit',
      'name': 'Service Credit',
      'description': 'Get 20% off your next service booking',
      'price': 3.99,
      'currency': 'USD',
      'duration': '30 days',
      'icon': Icons.credit_card,
      'color': Colors.green,
      'category': 'credit',
      'quantity': 1,
    },
    {
      'id': 'review_boost',
      'name': 'Review Boost',
      'description': 'Your reviews appear at the top for providers',
      'price': 1.99,
      'currency': 'USD',
      'duration': '14 days',
      'icon': Icons.trending_up,
      'color': Colors.blue,
      'category': 'boost',
      'quantity': 1,
    },
    {
      'id': 'emergency_call',
      'name': 'Emergency Call',
      'description': '24/7 emergency service access',
      'price': 9.99,
      'currency': 'USD',
      'duration': '24 hours',
      'icon': Icons.emergency,
      'color': Colors.red,
      'category': 'emergency',
      'quantity': 1,
    },
    {
      'id': 'premium_filter',
      'name': 'Premium Filter',
      'description': 'Access to premium service providers only',
      'price': 5.99,
      'currency': 'USD',
      'duration': '30 days',
      'icon': Icons.filter_alt,
      'color': Colors.purple,
      'category': 'filter',
      'quantity': 1,
    },
  ];

  final List<Map<String, dynamic>> _bundles = [
    {
      'id': 'starter_pack',
      'name': 'Starter Pack',
      'description': 'Perfect for new users',
      'originalPrice': 15.99,
      'discountedPrice': 9.99,
      'currency': 'USD',
      'items': [
        {'id': 'booking_boost', 'quantity': 2},
        {'id': 'service_credit', 'quantity': 1},
        {'id': 'review_boost', 'quantity': 1},
      ],
      'icon': Icons.card_giftcard,
      'color': Colors.blue,
      'popular': false,
    },
    {
      'id': 'pro_pack',
      'name': 'Pro Pack',
      'description': 'Most popular choice',
      'originalPrice': 29.99,
      'discountedPrice': 19.99,
      'currency': 'USD',
      'items': [
        {'id': 'booking_boost', 'quantity': 5},
        {'id': 'priority_ticket', 'quantity': 3},
        {'id': 'service_credit', 'quantity': 2},
        {'id': 'premium_filter', 'quantity': 1},
      ],
      'icon': Icons.workspace_premium,
      'color': Colors.purple,
      'popular': true,
    },
    {
      'id': 'ultimate_pack',
      'name': 'Ultimate Pack',
      'description': 'Everything you need',
      'originalPrice': 49.99,
      'discountedPrice': 34.99,
      'currency': 'USD',
      'items': [
        {'id': 'booking_boost', 'quantity': 10},
        {'id': 'priority_ticket', 'quantity': 5},
        {'id': 'service_credit', 'quantity': 5},
        {'id': 'review_boost', 'quantity': 3},
        {'id': 'emergency_call', 'quantity': 2},
        {'id': 'premium_filter', 'quantity': 2},
      ],
      'icon': Icons.diamond,
      'color': Colors.amber,
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to access virtual goods.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Virtual Goods'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Individual Items'),
              Tab(text: 'Bundles'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildIndividualItemsTab(),
            _buildBundlesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualItemsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final virtualBalance = (userData['virtualBalance'] ?? 0).toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.green[700], size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Virtual Balance',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              '\$${virtualBalance.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showAddBalanceDialog(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Add Funds'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Items Grid
              const Text(
                'Available Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

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
                  return _buildItemCard(item, virtualBalance);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBundlesTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final virtualBalance = (userData['virtualBalance'] ?? 0).toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.green[700], size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Virtual Balance',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              '\$${virtualBalance.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showAddBalanceDialog(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Add Funds'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bundles
              const Text(
                'Special Bundles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save money with these curated bundles',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 16),

              ..._bundles.map((bundle) => _buildBundleCard(bundle, virtualBalance)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, double balance) {
    final name = item['name'] as String;
    final description = item['description'] as String;
    final price = item['price'] as double;
    final currency = item['currency'] as String;
    final icon = item['icon'] as IconData;
    final color = item['color'] as Color;
    final duration = item['duration'] as String;

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
            Text(
              'Duration: $duration',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: balance >= price ? () => _showItemPurchaseDialog(item) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: balance >= price ? color : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  balance >= price ? 'Purchase' : 'Insufficient Balance',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBundleCard(Map<String, dynamic> bundle, double balance) {
    final name = bundle['name'] as String;
    final description = bundle['description'] as String;
    final originalPrice = bundle['originalPrice'] as double;
    final discountedPrice = bundle['discountedPrice'] as double;
    final currency = bundle['currency'] as String;
    final icon = bundle['icon'] as IconData;
    final color = bundle['color'] as Color;
    final isPopular = bundle['popular'] as bool;
    final items = bundle['items'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPopular ? 8 : 2,
      child: Container(
        decoration: isPopular
            ? BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MOST POPULAR',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const Spacer(),
                  Icon(icon, color: color, size: 32),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${discountedPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currency ${originalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${((originalPrice - discountedPrice) / originalPrice * 100).round()}% OFF',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Bundle Contents:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...items.map((item) {
                final itemInfo = _getItemInfo(item['id']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(itemInfo['icon'], color: itemInfo['color'], size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(itemInfo['name'])),
                      Text('x${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: balance >= discountedPrice ? () => _showBundlePurchaseDialog(bundle) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: balance >= discountedPrice ? color : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    balance >= discountedPrice ? 'Purchase Bundle' : 'Insufficient Balance',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
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
            const Text('Add funds to your virtual balance for virtual goods.'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (USD)',
                prefixText: '\$',
                hintText: '10.00',
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

  void _showItemPurchaseDialog(Map<String, dynamic> item) {
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
              'Price: ${item['currency']} ${item['price'].toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Duration: ${item['duration']}'),
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
              await _processItemPurchase(item);
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _showBundlePurchaseDialog(Map<String, dynamic> bundle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${bundle['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to purchase:'),
            const SizedBox(height: 8),
            Text(
              bundle['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(bundle['description']),
            const SizedBox(height: 8),
            Text(
              'Price: ${bundle['currency']} ${bundle['discountedPrice'].toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Original Price: ${bundle['currency']} ${bundle['originalPrice'].toStringAsFixed(2)}',
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
            const SizedBox(height: 8),
            const Text('Bundle includes:'),
            ...bundle['items'].map((item) {
              final itemInfo = _getItemInfo(item['id']);
              return Text('• ${itemInfo['name']} x${item['quantity']}');
            }).toList(),
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
              await _processBundlePurchase(bundle);
            },
            child: const Text('Purchase'),
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
          content: Text('Successfully added \$${amount.toStringAsFixed(2)} to your balance'),
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

  Future<void> _processItemPurchase(Map<String, dynamic> item) async {
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

      // Add item to user's inventory
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'virtualGoods': FieldValue.arrayUnion([{
          'itemId': item['id'],
          'name': item['name'],
          'purchaseDate': FieldValue.serverTimestamp(),
          'expiryDate': _calculateExpiryDate(item['duration']),
          'quantity': item['quantity'],
        }]),
      });

      // Record purchase
      await FirebaseFirestore.instance
          .collection('userPurchases')
          .add({
        'userId': user!.uid,
        'itemId': item['id'],
        'itemName': item['name'],
        'amount': itemPrice,
        'currency': item['currency'],
        'purchaseDate': FieldValue.serverTimestamp(),
        'duration': item['duration'],
        'status': 'active',
        'type': 'virtual_good',
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

  Future<void> _processBundlePurchase(Map<String, dynamic> bundle) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final currentBalance = (userData['virtualBalance'] ?? 0).toDouble();
      final bundlePrice = bundle['discountedPrice'] as double;

      if (currentBalance < bundlePrice) {
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
        'virtualBalance': FieldValue.increment(-bundlePrice),
      });

      // Add all items from bundle to user's inventory
      final items = bundle['items'] as List<dynamic>;
      for (final item in items) {
        final itemInfo = _getItemInfo(item['id']);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'virtualGoods': FieldValue.arrayUnion([{
            'itemId': item['id'],
            'name': itemInfo['name'],
            'purchaseDate': FieldValue.serverTimestamp(),
            'expiryDate': _calculateExpiryDate('30 days'), // Default duration for bundle items
            'quantity': item['quantity'],
          }]),
        });
      }

      // Record bundle purchase
      await FirebaseFirestore.instance
          .collection('userPurchases')
          .add({
        'userId': user!.uid,
        'itemId': bundle['id'],
        'itemName': bundle['name'],
        'amount': bundlePrice,
        'currency': bundle['currency'],
        'purchaseDate': FieldValue.serverTimestamp(),
        'duration': 'bundle',
        'status': 'active',
        'type': 'bundle',
        'originalPrice': bundle['originalPrice'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased ${bundle['name']}!'),
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

  Timestamp _calculateExpiryDate(String duration) {
    final now = DateTime.now();
    switch (duration) {
      case '1 use':
        return Timestamp.fromDate(now.add(const Duration(days: 365))); // 1 year for single use
      case '7 days':
        return Timestamp.fromDate(now.add(const Duration(days: 7)));
      case '14 days':
        return Timestamp.fromDate(now.add(const Duration(days: 14)));
      case '24 hours':
        return Timestamp.fromDate(now.add(const Duration(days: 1)));
      case '30 days':
      default:
        return Timestamp.fromDate(now.add(const Duration(days: 30)));
    }
  }

  Map<String, dynamic> _getItemInfo(String itemId) {
    switch (itemId) {
      case 'booking_boost':
        return {
          'name': 'Booking Boost',
          'icon': Icons.rocket_launch,
          'color': Colors.red,
        };
      case 'priority_ticket':
        return {
          'name': 'Priority Ticket',
          'icon': Icons.confirmation_number,
          'color': Colors.orange,
        };
      case 'service_credit':
        return {
          'name': 'Service Credit',
          'icon': Icons.credit_card,
          'color': Colors.green,
        };
      case 'review_boost':
        return {
          'name': 'Review Boost',
          'icon': Icons.trending_up,
          'color': Colors.blue,
        };
      case 'emergency_call':
        return {
          'name': 'Emergency Call',
          'icon': Icons.emergency,
          'color': Colors.red,
        };
      case 'premium_filter':
        return {
          'name': 'Premium Filter',
          'icon': Icons.filter_alt,
          'color': Colors.purple,
        };
      default:
        return {
          'name': itemId,
          'icon': Icons.star,
          'color': Colors.grey,
        };
    }
  }
}