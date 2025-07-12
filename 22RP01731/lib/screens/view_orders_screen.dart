import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as model_order;

class ViewOrdersScreen extends StatefulWidget {
  const ViewOrdersScreen({super.key});

  @override
  State<ViewOrdersScreen> createState() => _ViewOrdersScreenState();
}

class _ViewOrdersScreenState extends State<ViewOrdersScreen> {
  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', 'pending', 'completed', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Orders')),
      body: Column(
        children: [
          // Status Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
          ),
          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }
                final orders = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return model_order.Order.fromMap(doc.id, data);
                }).where((order) => _selectedStatus == 'All' || order.status == _selectedStatus).toList();
                
                if (orders.isEmpty) {
                  return Center(child: Text('No orders found with status: $_selectedStatus'));
                }
                
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('Order #${order.id.substring(0, 6)}...'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(order.userId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                  final firstName = userData?['firstName'] ?? 'Unknown';
                                  final lastName = userData?['lastName'] ?? '';
                                  return Text('Customer: $firstName $lastName');
                                }
                                return const Text('Customer: Loading...');
                              },
                            ),
                            Text('Total: \$${order.total.toStringAsFixed(2)}'),
                            Text(
                              'Status: ${order.status}',
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Date: ${order.date.toLocal().toString().split('.')[0]}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (status) async {
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(order.id)
                                .update({'status': status});
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'pending', child: Text('Pending')),
                            const PopupMenuItem(value: 'completed', child: Text('Completed')),
                            const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                          ],
                          child: const Icon(Icons.more_vert),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => OrderDetailsDialog(order: order),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}

class OrderDetailsDialog extends StatelessWidget {
  final model_order.Order order;
  const OrderDetailsDialog({super.key, required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Order #${order.id.substring(0, 6)}...'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${order.date.toLocal().toString().split('.')[0]}'),
            Text(
              'Status: ${order.status}',
              style: TextStyle(
                color: _getStatusColor(order.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Total: \$${order.total.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            const Text('Customer Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(order.userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final firstName = userData?['firstName'] ?? 'Unknown';
                  final lastName = userData?['lastName'] ?? '';
                  return Text('Name: $firstName $lastName');
                }
                return const Text('Name: Loading...');
              },
            ),
            Text('Address: ${order.address}'),
            Text('Phone: ${order.phone}'),
            const Divider(),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${item.product.name} x${item.quantity} - \$${item.totalPrice.toStringAsFixed(2)}'),
            )),
            const SizedBox(height: 16),
            const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'pending',
                'completed',
                'cancelled',
              ].map((status) => ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(order.id)
                      .update({'status': status});
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: order.status == status ? _getStatusColor(status) : Colors.grey.shade300,
                  foregroundColor: order.status == status ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: order.status == status ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }
} 