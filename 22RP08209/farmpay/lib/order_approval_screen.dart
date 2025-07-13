import 'package:flutter/material.dart';

class OrderApprovalScreen extends StatefulWidget {
  const OrderApprovalScreen({Key? key}) : super(key: key);

  @override
  State<OrderApprovalScreen> createState() => _OrderApprovalScreenState();
}

class _OrderApprovalScreenState extends State<OrderApprovalScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    // TODO: Fetch user orders from Firestore
    await Future.delayed(const Duration(seconds: 1)); // Simulate loading
    setState(() {
      orders = <Map<String, dynamic>>[];
      orders = [
        {'id': 1, 'user_name': 'John Doe', 'total_amount': 12000, 'status': 'pending', 'payment_method': 'Cash', 'created_at': '2023-10-26T10:00:00Z', 'user_id': 1},
        {'id': 2, 'user_name': 'Jane Smith', 'total_amount': 5000, 'status': 'approved', 'payment_method': 'Bank Transfer', 'created_at': '2023-10-26T11:00:00Z', 'user_id': 2},
        {'id': 3, 'user_name': 'Peter Jones', 'total_amount': 2000, 'status': 'rejected', 'payment_method': 'Cash', 'created_at': '2023-10-26T12:00:00Z', 'user_id': 1},
      ];
      isLoading = false;
    });
  }

  Future<void> _updateOrderStatus(int orderId, String status, int userId) async {
    // TODO: Update order status and send notification in Firestore
    print('Updating order $orderId to status: $status for user $userId');
    await Future.delayed(const Duration(seconds: 1)); // Simulate update
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Approval'), backgroundColor: Colors.deepPurple),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders yet.'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text('Order: ${order['id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User: ${order['user_name']}'),
                            Text('Total: ${order['total_amount']} RWF'),
                            Text('Status: ${order['status']}'),
                            Text('Payment Method: ${order['payment_method']}'),
                            Text('Date: ${DateTime.parse(order['created_at']).toString().split(' ')[0]}'),
                          ],
                        ),
                        trailing: order['status'] == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _updateOrderStatus(order['id'], 'approved', order['user_id']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _updateOrderStatus(order['id'], 'rejected', order['user_id']),
                                  ),
                                ],
                              )
                            : _getStatusIcon(order['status']),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Icon(Icons.schedule, color: Colors.orange);
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'paid':
        return const Icon(Icons.payment, color: Colors.blue);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }
} 