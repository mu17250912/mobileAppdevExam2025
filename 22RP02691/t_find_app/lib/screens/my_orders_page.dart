import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:badges/badges.dart' as badges;
import 'search_page.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key}) : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  bool _showOngoing = true;
  int _unreadNotificationCount = 0;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _listenNotifications();
  }

  void _listenNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          final notifs = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
            };
          }).toList();
          setState(() {
            _notifications = notifs;
            _unreadNotificationCount = notifs.where((n) => n['read'] == false).length;
          });
        });
    }
  }

  void _showNotificationsModal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Mark all as read
    final unread = _notifications.where((n) => n['read'] == false).toList();
    for (final notif in unread) {
      await FirebaseFirestore.instance.collection('notifications').doc(notif['id']).update({'read': true});
    }
    setState(() {
      _unreadNotificationCount = 0;
    });
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: _notifications.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return ListTile(
                        leading: Icon(
                          notif['type'] == 'order' ? Icons.shopping_cart : Icons.notifications,
                          color: notif['read'] == false ? Colors.blue : Colors.grey,
                        ),
                        title: Text(notif['title'] ?? ''),
                        subtitle: Text(notif['body'] ?? ''),
                        trailing: notif['read'] == false
                          ? Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            )
                          : null,
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _ongoingOrders = [
    {
      'id': '12345',
      'status': 'Preparing',
      'restaurant': "Mama's Italian Kitchen",
      'food': 'Homemade Lasagna',
      'orderTime': '2:30 PM',
      'estimatedTime': '3:15 PM',
      'total': '\$24.99',
      'items': ['Lasagna', 'Garlic Bread', 'Caesar Salad'],
    },
    {
      'id': '12346',
      'status': 'On the way',
      'restaurant': 'Ineza Restaurant',
      'food': 'Isombe foods',
      'orderTime': '2:00 PM',
      'estimatedTime': '2:45 PM',
      'total': '\$18.50',
      'items': ['Isombe foods', 'Ugali', 'Chapati'],
    },
  ];

  final List<Map<String, dynamic>> _recentOrders = [
    {
      'id': '12344',
      'status': 'Delivered',
      'restaurant': 'Isombe foods',
      'location': 'Nyagatare, RWANDA',
      'orderTime': 'Yesterday, 1:30 PM',
      'deliveryTime': '2:15 PM',
      'total': '\$15.99',
      'rating': 5,
      'items': ['Isombe foods', 'Rice', 'Beans'],
    },
    {
      'id': '12343',
      'status': 'Delivered',
      'restaurant': 'Sushi Master',
      'location': 'Kigali, RWANDA',
      'orderTime': '2 days ago, 7:00 PM',
      'deliveryTime': '7:45 PM',
      'total': '\$32.50',
      'rating': 4,
      'items': ['Sushi Roll', 'Miso Soup', 'Green Tea'],
    },
  ];

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restaurant: ${order['restaurant']}'),
            if (order['location'] != null) Text('Location: ${order['location']}'),
            Text('Status: ${order['status']}'),
            Text('Order Time: ${order['orderTime']}'),
            if (order['estimatedTime'] != null) Text('Estimated: ${order['estimatedTime']}'),
            if (order['deliveryTime'] != null) Text('Delivered: ${order['deliveryTime']}'),
            Text('Total: ${order['total']}'),
            if (order['rating'] != null) Row(
              children: [
                Text('Rating: ${order['rating']}'),
                const Icon(Icons.star, color: Colors.amber, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order['items'].map<Widget>((item) => Text('• $item')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (order['status'] == 'Preparing' || order['status'] == 'On the way')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tracking order #${order['id']}...')),
                );
              },
              child: const Text('Track Order'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF9C7B7B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C7B7B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Orders', style: TextStyle(color: Colors.black)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: badges.Badge(
              showBadge: _unreadNotificationCount > 0,
              badgeContent: Text(
                _unreadNotificationCount > 0 ? _unreadNotificationCount.toString() : '',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.notifications_none, color: Colors.black),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: user?.uid)
            .orderBy('orderTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('You have no orders', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          final orders = snapshot.data!.docs;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      'Order: ${order['foodName'] ?? order['food'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['status'] ?? '',
                          style: TextStyle(
                            color: order['status'] == 'Delivered' ? Colors.green : 
                                   order['status'] == 'Preparing' ? Colors.orange : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('${order['culture'] ?? ''} • ${order['location'] ?? ''}'),
                        Text(order['desc'] ?? ''),
                        if (order['price'] != null) Text('Price: ${order['price']} FRW'),
                        Text(order['orderTime'] != null ? order['orderTime'].toString() : ''),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((order['status'] ?? '') == 'Paid')
                          ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Paid'),
                          )
                        else
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Pay for Order'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.phone_android, color: Colors.yellow),
                                        title: const Text('MTN Mobile Money'),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final controller = TextEditingController();
                                          final amountController = TextEditingController(text: order['price']?.toString() ?? '');
                                          final result = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('MTN Mobile Money Payment'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller: controller,
                                                    keyboardType: TextInputType.phone,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Enter MTN Number',
                                                      prefixText: '+250 ',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextField(
                                                    controller: amountController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Amount to Pay (FRW)',
                                                    ),
                                                    enabled: false, // Prevent editing
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    if (controller.text.isNotEmpty) {
                                                      Navigator.pop(context, true);
                                                    }
                                                  },
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (result == true) {
                                            await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Complete Payment'),
                                                content: const Text('Press this code on your phone: *182*7*1#'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            try {
                                              // Use the document ID from the snapshot to ensure correct update
                                              final docId = snapshot.data!.docs[index].id;
                                              final ref = FirebaseFirestore.instance.collection('orders').doc(docId);
                                              print('DEBUG: Updating order with docId: $docId');
                                              await ref.update({'status': 'Paid'});
                                              print('DEBUG: Order update complete.');
                                              // Add notification for the buyer
                                              await FirebaseFirestore.instance.collection('notifications').add({
                                                'userId': order['buyerId'],
                                                'title': 'Order Paid',
                                                'body': 'Your order for ${order['foodName'] ?? order['food'] ?? ''} has been paid!',
                                                'timestamp': FieldValue.serverTimestamp(),
                                                'read': false,
                                                'type': 'order_paid',
                                                'orderId': docId,
                                              });
                                              if (mounted) setState(() {});
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Order marked as Paid!')),
                                                );
                                              }
                                            } catch (e) {
                                              print('ERROR: Failed to update order status: $e');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to mark as Paid: $e')),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.phone_android, color: Colors.red),
                                        title: const Text('Airtel Money'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Simulated payment via Airtel!')),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.account_balance, color: Colors.blue),
                                        title: const Text('Bank'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Simulated payment via Bank!')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Pay'),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: (order['status'] ?? '') == 'Paid' ? null : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cancel Order'),
                                content: const Text('Are you sure you want to cancel this order?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              // Delete order from Firestore
                              await orders[index].reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order cancelled.')),
                              );
                            }
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF9C7B7B),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        currentIndex: 1, // My Orders is index 1
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.blue),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
} 